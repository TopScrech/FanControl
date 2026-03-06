import Foundation

enum LicenseVerificationReason: String, Codable {
    case active, notFound = "not_found", inactive, deviceLimitReached = "device_limit_reached"
}

extension LicenseVerificationReason {
    var localizedStatusText: String {
        switch self {
        case .active:
            String(localized: "License is active")
        case .notFound:
            String(localized: "License was not found")
        case .inactive:
            String(localized: "License is inactive")
        case .deviceLimitReached:
            String(localized: "Device limit reached for this license")
        }
    }
}
