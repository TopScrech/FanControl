import Foundation

extension Bundle {
    var versionTag: String {
        let version =
        (infoDictionary?["CFBundleShortVersionString"] as? String) ??
        (infoDictionary?["CFBundleVersion"] as? String) ??
        "Unknown"
        
        guard !version.hasPrefix("v") else {
            return version
        }
        
        return "v\(version)"
    }
}
