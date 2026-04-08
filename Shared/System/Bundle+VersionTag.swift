import Foundation

extension Bundle {
    nonisolated var appVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ??
        (infoDictionary?["CFBundleVersion"] as? String) ??
        "Unknown"
    }
    
    nonisolated var versionTag: String {
        let version = appVersion
        
        guard !version.hasPrefix("v") else {
            return version
        }
        
        return "v\(version)"
    }
}
