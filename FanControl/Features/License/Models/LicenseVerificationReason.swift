import Foundation

enum LicenseVerificationReason: String, Codable {
    case active, notFound = "not_found", inactive, deviceLimitReached = "device_limit_reached"
    
    var localizedStatusText: String {
        switch self {
        case .active: String(localized: "Active")
        case .notFound: String(localized: "Not found")
        case .inactive: String(localized: "Inactive")
        case .deviceLimitReached: String(localized: "Device limit reached")
        }
    }
}
