import Foundation
import OSLog
import ServiceManagement

@Observable
final class FanVM {
    var fans: [Fan] = []
    var selectedFanID = 0
    var errorText: String?
    
    private static let logger = Logger(subsystem: "FanControl", category: "FanVM")
    private let localSMC: LocalSMCService?
    private var remoteSMC: RemoteSMCService?
    private var timer: Timer?
    private var holdingManualOverride = false
    private var helperInstallInProgress = false
    private let isRoot = geteuid() == 0
    
    init() {
        Self.logger.info("Initializing FanVM")
        Self.logHelperBundleDiagnostics()
        
        var localError: String?
        
        do {
            localSMC = try LocalSMCService()
            Self.logger.info("Local SMC client ready")
        } catch {
            localSMC = nil
            localError = error.localizedDescription
            Self.logger.error("Local SMC client init failed: \(error.localizedDescription, privacy: .public)")
        }
        
        if localSMC == nil {
            errorText = localError
        }
        
        connectHelperIfAvailable()
        
        Task {
            await refresh()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task {
                await self?.tick()
            }
        }
    }
    
    deinit {
        Self.logger.info("Deinitializing FanVM")
        timer?.invalidate()
    }
    
    var selectedFan: Fan? {
        fans.first(where: { $0.id == selectedFanID })
    }
    
    private static func logHelperBundleDiagnostics() {
        let bundleURL = Bundle.main.bundleURL
        
        let launchdURL = bundleURL.appendingPathComponent(
            "Contents/Library/LaunchDaemons/\(FanControlXPCConstants.launchdPlistName)"
        )
        
        let helperURL = bundleURL.appendingPathComponent(
            "Contents/Library/PrivilegedHelperTools/FanControlHelper"
        )
        
        let fm = FileManager.default
        
        Self.logger.info("App bundle path: \(bundleURL.path, privacy: .public)")
        Self.logger.info("Launchd plist path: \(launchdURL.path, privacy: .public)")
        Self.logger.info("Launchd plist exists: \(fm.fileExists(atPath: launchdURL.path))")
        Self.logger.info("Helper tool path: \(helperURL.path, privacy: .public)")
        Self.logger.info("Helper tool exists: \(fm.fileExists(atPath: helperURL.path))")
    }
    
    func tick() async {
        if holdingManualOverride, let smc = writeService {
            do {
                try await smc.keepAliveManualOverride()
            } catch {
                errorText = error.localizedDescription
                Self.logger.error("Manual keep-alive failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        await refresh()
    }
    
    func refresh() async {
        guard let smc = activeService else {
            Self.logger.info("Refresh skipped: no active SMC service")
            return
        }
        
        do {
            Self.logger.info("Refresh starting")
            let snapshots = try await smc.readFans()
            Self.logger.info("Refresh readFans count=\(snapshots.count, privacy: .public)")
            fans = snapshots
            errorText = nil
            
            if selectedFanID >= fans.count {
                selectedFanID = 0
            }
        } catch {
            errorText = error.localizedDescription
            Self.logger.error("Refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func setManualRPM(_ rpm: Double) async {
        guard let fan = selectedFan else {
            Self.logger.info("Manual request ignored: no selected fan")
            return
        }
        
        let helperStatus = await ensureHelperConnected()
        
        guard let smc = writeService else {
            setWriteUnavailableError(status: helperStatus)
            Self.logger.info("Manual request ignored: no writable SMC client")
            return
        }
        
        do {
            Self.logger.info("Manual request fan=\(fan.id, privacy: .public) rpm=\(rpm, privacy: .public) mode=\(fan.mode, privacy: .public)")
            try await smc.setFanManualRPM(fanID: fan.id, rpm: rpm)
            holdingManualOverride = true
            await refresh()
            Self.logger.info("Manual applied fan=\(fan.id, privacy: .public) rpm=\(rpm, privacy: .public)")
        } catch {
            Self.logger.error("Manual failed fan=\(fan.id, privacy: .public) rpm=\(rpm, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            errorText = error.localizedDescription
        }
    }
    
    func setAuto() async {
        guard let fan = selectedFan else {
            Self.logger.info("Auto request ignored: missing SMC or selected fan")
            return
        }
        
        let helperStatus = await ensureHelperConnected()
        
        guard let smc = writeService else {
            setWriteUnavailableError(status: helperStatus)
            Self.logger.info("Auto request ignored: missing writable SMC client")
            return
        }
        
        do {
            Self.logger.info("Auto request fan=\(fan.id, privacy: .public) mode=\(fan.mode, privacy: .public)")
            try await smc.setFanAuto(fanID: fan.id)
            holdingManualOverride = false
            await refresh()
            Self.logger.info("Auto applied fan=\(fan.id, privacy: .public)")
        } catch {
            Self.logger.error("Auto failed fan=\(fan.id, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            errorText = error.localizedDescription
        }
    }
    
    private var activeService: SMCService? {
        localSMC ?? remoteSMC
    }
    
    private var writeService: SMCService? {
        if let remoteSMC {
            return remoteSMC
        }

        return isRoot ? localSMC : nil
    }
    
    private func connectHelperIfAvailable() {
        let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)
        
        if service.status == .enabled {
            remoteSMC = RemoteSMCService()
            Self.logger.info("SMC helper connected")
        } else {
            Self.logger.info("SMC helper status: \(String(describing: service.status), privacy: .public)")
        }
    }
    
    private func ensureHelperConnected() async -> SMAppService.Status {
        if remoteSMC != nil {
            return .enabled
        }
        
        let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)
        
        guard !helperInstallInProgress else { return service.status }
        
        helperInstallInProgress = true
        defer { helperInstallInProgress = false }
        
        switch service.status {
        case .enabled:
            remoteSMC = RemoteSMCService()
            return service.status
            
        case .requiresApproval:
            return service.status
            
        case .notFound, .notRegistered:
            break
            
        @unknown default:
            return service.status
        }
        
        do {
            let status = try SMCHelperInstaller.registerIfNeeded()
            Self.logger.info("SMC helper register status: \(String(describing: status), privacy: .public)")
            
            if status == .enabled {
                remoteSMC = RemoteSMCService()
            }
            
            return status
        } catch {
            errorText = error.localizedDescription
            Self.logger.error("SMC helper register failed: \(error.localizedDescription, privacy: .public)")
            return service.status
        }
    }
    
    private func setWriteUnavailableError(status: SMAppService.Status) {
        if isRoot {
            return
        }
        
        switch status {
        case .requiresApproval:
            errorText = "Helper needs approval in System Settings > General > Login Items > Allow in Background"
            
        case .notFound:
            let bundlePath = Bundle.main.bundleURL.path
            let helperPath = Bundle.main.bundleURL
                .appendingPathComponent("Contents/Library/PrivilegedHelperTools/FanControlHelper")
                .path
            let plistPath = Bundle.main.bundleURL
                .appendingPathComponent(
                    "Contents/Library/LaunchDaemons/\(FanControlXPCConstants.launchdPlistName)"
                )
                .path
            let systemHelperPath = "/Library/PrivilegedHelperTools/FanControlHelper"
            let systemPlistPath = "/Library/LaunchDaemons/\(FanControlXPCConstants.launchdPlistName)"
            let fm = FileManager.default
            let helperExists = fm.fileExists(atPath: helperPath)
            let plistExists = fm.fileExists(atPath: plistPath)
            let systemHelperExists = fm.fileExists(atPath: systemHelperPath)
            let systemPlistExists = fm.fileExists(atPath: systemPlistPath)

            errorText = """
Helper not found in app bundle
Bundle: \(bundlePath)
Helper exists: \(helperExists)
Plist exists: \(plistExists)
System helper exists: \(systemHelperExists)
System plist exists: \(systemPlistExists)
"""
        case .notRegistered:
            errorText = "Helper not registered. Run from /Applications and try again"
            
        case .enabled:
            errorText = "Helper connected but no writable SMC client is available"
            
        @unknown default:
            errorText = "Helper status unknown. Try again after approving or reinstalling"
        }
    }
}
