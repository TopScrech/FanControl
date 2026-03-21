import Foundation
import CoreSMC
import ServiceManagement

final class FanCLIService {
    private static let manualRetryAttempts = 15
    private static let manualRetryInterval: Duration = .seconds(1)
    private static let rpmMatchTolerance = 1.0
    
    private let localSMC: LocalSMCService?
    private let localSMCInitError: Error?
    private var remoteSMC: RemoteSMCService?
    private let isRoot = geteuid() == 0
    
    init() {
        do {
            localSMC = try LocalSMCService()
            localSMCInitError = nil
        } catch {
            localSMC = nil
            localSMCInitError = error
        }
        
        connectHelperIfAvailable()
    }
    
    func readFans() async throws -> [Fan] {
        if let localSMC {
            do {
                return try await localSMC.readFans()
            } catch {
                if let remoteSMC {
                    return try await remoteSMC.readFans()
                }
                
                throw error
            }
        }
        
        if let remoteSMC {
            return try await remoteSMC.readFans()
        }
        
        if let localSMCInitError {
            throw localSMCInitError
        }
        
        throw FanCLIError.failure("SMC unavailable")
    }
    
    func setManualRPM(_ rpm: Int, userFacingFanID: Int?) async throws {
        let fans = try await readFans()
        let targetFans = try resolveFans(from: fans, userFacingFanID: userFacingFanID)
        
        guard !targetFans.isEmpty else {
            throw FanCLIError.failure("No fans found")
        }
        
        try validateRPM(rpm, for: targetFans)
        
        let smc = try writableService()
        let targetRPMsByFanID = Dictionary(uniqueKeysWithValues: targetFans.map { ($0.id, Double(rpm)) })
        
        try await applyManualRPM(targetFans: targetFans, targetRPMsByFanID: targetRPMsByFanID, smc: smc)
    }
    
    func setMinimumRPM(userFacingFanID: Int?) async throws {
        try await setBoundaryRPM(userFacingFanID: userFacingFanID) {
            Int($0.minRPM.rounded())
        }
    }
    
    func setMaximumRPM(userFacingFanID: Int?) async throws {
        try await setBoundaryRPM(userFacingFanID: userFacingFanID) {
            Int($0.maxRPM.rounded())
        }
    }
    
    func setAuto(userFacingFanID: Int?) async throws {
        let fans = try await readFans()
        let targetFans = try resolveFans(from: fans, userFacingFanID: userFacingFanID)
        
        guard !targetFans.isEmpty else {
            throw FanCLIError.failure("No fans found")
        }
        
        let smc = try writableService()
        
        for fan in targetFans {
            try await smc.setFanAuto(fanID: fan.id)
        }
    }
    
    private func connectHelperIfAvailable() {
        let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)
        
        if service.status == .enabled {
            remoteSMC = RemoteSMCService()
        }
    }
    
    private func writableService() throws -> SMCService {
        if let remoteSMC {
            return remoteSMC
        }
        
        if isRoot, let localSMC {
            return localSMC
        }
        
        let helperStatus = try SMCHelperInstaller.registerIfNeeded()
        
        if helperStatus == .enabled {
            let remoteSMC = RemoteSMCService()
            self.remoteSMC = remoteSMC
            return remoteSMC
        }
        
        throw FanCLIError.failure(helperMessage(for: helperStatus))
    }
    
    private func resolveFans(from fans: [Fan], userFacingFanID: Int?) throws -> [Fan] {
        if let userFacingFanID {
            guard let fan = fans.first(where: { $0.userFacingID == userFacingFanID }) else {
                throw FanCLIError.failure("Fan \(userFacingFanID) was not found")
            }
            
            return [fan]
        }
        
        return fans.sorted { $0.id < $1.id }
    }
    
    private func validateRPM(_ rpm: Int, for fans: [Fan]) throws {
        for fan in fans {
            let minimumRPM = Int(fan.minRPM.rounded())
            let maximumRPM = Int(fan.maxRPM.rounded())
            
            guard Double(rpm) >= fan.minRPM, Double(rpm) <= fan.maxRPM else {
                throw FanCLIError.failure("\(fan.cliDisplayName) supports \(minimumRPM)...\(maximumRPM) RPM")
            }
        }
    }
    
    private func setBoundaryRPM(userFacingFanID: Int?, rpm: (Fan) -> Int) async throws {
        let fans = try await readFans()
        let targetFans = try resolveFans(from: fans, userFacingFanID: userFacingFanID)
        
        guard !targetFans.isEmpty else {
            throw FanCLIError.failure("No fans found")
        }
        
        let smc = try writableService()
        let targetRPMsByFanID = Dictionary(uniqueKeysWithValues: targetFans.map { ($0.id, Double(rpm($0))) })
        
        try await applyManualRPM(targetFans: targetFans, targetRPMsByFanID: targetRPMsByFanID, smc: smc)
    }
    
    private func applyManualRPM(
        targetFans: [Fan],
        targetRPMsByFanID: [Int: Double],
        smc: SMCService
    ) async throws {
        var lastAttemptError: Error?
        var latestFansByID = [Int: Fan]()
        
        for attempt in 1...Self.manualRetryAttempts {
            for fan in targetFans {
                guard let targetRPM = targetRPMsByFanID[fan.id] else { continue }
                
                do {
                    try await smc.setFanManualRPM(fanID: fan.id, rpm: targetRPM)
                } catch {
                    lastAttemptError = error
                }
            }
            
            do {
                latestFansByID = Dictionary(uniqueKeysWithValues: try await readFans().map { ($0.id, $0) })
                
                let allTargetsReached = targetFans.allSatisfy {
                    guard
                        let targetRPM = targetRPMsByFanID[$0.id],
                        let latestFan = latestFansByID[$0.id]
                    else {
                        return false
                    }
                    
                    return Self.rpmMatches(latestFan.targetRPM, targetRPM)
                }
                
                if allTargetsReached {
                    return
                }
            } catch {
                lastAttemptError = error
            }
            
            if attempt < Self.manualRetryAttempts {
                try await Task.sleep(for: Self.manualRetryInterval)
            }
        }
        
        if latestFansByID.isEmpty, let lastAttemptError {
            throw lastAttemptError
        }
        
        if let unmatchedFan = targetFans.first(where: {
            guard
                let targetRPM = targetRPMsByFanID[$0.id],
                let latestFan = latestFansByID[$0.id]
            else {
                return true
            }
            
            return !Self.rpmMatches(latestFan.targetRPM, targetRPM)
        }) {
            let targetRPM = Int((targetRPMsByFanID[unmatchedFan.id] ?? unmatchedFan.targetRPM).rounded())
            
            if let latestFan = latestFansByID[unmatchedFan.id] {
                let latestRPM = Int(latestFan.targetRPM.rounded())
                
                throw FanCLIError.failure(
                    "\(unmatchedFan.cliDisplayName) did not reach \(targetRPM) RPM. Last target was \(latestRPM) RPM"
                )
            }
            
            throw FanCLIError.failure(
                "\(unmatchedFan.cliDisplayName) did not reach \(targetRPM) RPM"
            )
        }
        
        if let lastAttemptError {
            throw lastAttemptError
        }
    }
    
    private static func rpmMatches(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) <= rpmMatchTolerance
    }
    
    private func helperMessage(for status: SMAppService.Status) -> String {
        switch status {
        case .requiresApproval:
            return "Helper needs approval in System Settings > General > Login Items > Allow in Background"
            
        case .notFound:
            let bundlePath = AppBundleLocator.current.bundleURL.path(percentEncoded: false)
            let helperPath = AppBundleLocator.current.bundleURL
                .appending(path: "Contents/Library/PrivilegedHelperTools/FanControlHelper")
                .path(percentEncoded: false)
            let plistPath = AppBundleLocator.current.bundleURL
                .appending(path: "Contents/Library/LaunchDaemons/\(FanControlXPCConstants.launchdPlistName)")
                .path(percentEncoded: false)
            let systemHelperPath = "/Library/PrivilegedHelperTools/FanControlHelper"
            let systemPlistPath = "/Library/LaunchDaemons/\(FanControlXPCConstants.launchdPlistName)"
            let fm = FileManager.default
            
            return """
Helper not found in app bundle

App bundle
Bundle: \(bundlePath)
Helper exists: \(fm.fileExists(atPath: helperPath))
Plist exists: \(fm.fileExists(atPath: plistPath))

Installed system files
Helper exists: \(fm.fileExists(atPath: systemHelperPath))
Plist exists: \(fm.fileExists(atPath: systemPlistPath))
"""
            
        case .notRegistered:
            return "Helper not registered. Run the embedded tool from /Applications/FanControl.app"
            
        case .enabled:
            return "Helper connected but no writable SMC client is available"
            
        @unknown default:
            return "Helper status is unknown"
        }
    }
}
