import ServiceManagement
import OSLog

struct SMCHelperInstaller {
    private static let logger = Logger(subsystem: "FanControl", category: "SMCHelperInstaller")
    
    static func registerIfNeeded() throws -> SMAppService.Status {
        let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)
        
        if service.status == .enabled {
            return service.status
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
}
