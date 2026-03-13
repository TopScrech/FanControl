import Foundation
import ServiceManagement
import OSLog

struct SMCHelperInstaller {
    private static let logger = Logger(subsystem: "FanControl", category: "SMCHelperInstaller")
    
    static func registerIfNeeded() throws -> SMAppService.Status {
        let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)
        
        if service.status == .enabled, !shouldRefreshEnabledHelper() {
            return service.status
        }
        
        if service.status == .enabled {
            Self.logger.info("Refreshing enabled helper for bundle \(Bundle.main.bundleURL.path, privacy: .public)")
            
            do {
                try service.unregister()
            } catch {
                let nsError = error as NSError
                Self.logger.error("Helper unregister failed: \(nsError.domain) code=\(nsError.code) \(nsError)")
            }
        }
        
        do {
            try service.register()
        } catch {
            let nsError = error as NSError
            Self.logger.error("Helper register failed: \(nsError.domain) code=\(nsError.code) \(nsError)")
            throw error
        }
        
        return service.status
    }
    
    static func shouldRefreshEnabledHelper() -> Bool {
        guard let authority = currentCodeSigningAuthority() else {
            return false
        }
        
        return !authority.hasPrefix("Developer ID Application:")
    }
    
    private static func currentCodeSigningAuthority() -> String? {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/codesign")
        process.arguments = ["-dvvv", Bundle.main.bundleURL.path(percentEncoded: false)]
        
        let standardError = Pipe()
        process.standardOutput = Pipe()
        process.standardError = standardError
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        
        guard process.terminationStatus == 0 else {
            return nil
        }
        
        let description = String(
            decoding: standardError.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )
        
        guard let authorityLine = description
            .split(separator: "\n")
            .first(where: { $0.hasPrefix("Authority=") })
        else {
            return nil
        }
        
        return String(authorityLine.dropFirst("Authority=".count))
    }
}
