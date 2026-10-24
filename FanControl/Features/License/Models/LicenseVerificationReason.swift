import SwiftUI

enum LicenseVerificationReason: String, Codable {
    case active, notFound = "not_found", inactive, deviceLimitReached = "device_limit_reached"
    
    var localizedStatusText: LocalizedStringKey {
        switch self {
        case .active: "Active"
        case .notFound: "Not found"
        case .inactive: "Inactive"
        case .deviceLimitReached: "Device limit reached"
        }
    }
}
