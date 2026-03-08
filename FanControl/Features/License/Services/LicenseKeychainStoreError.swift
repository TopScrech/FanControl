import Foundation

enum LicenseKeychainStoreError: LocalizedError {
    case saveFailed(status: OSStatus),
         deleteFailed(status: OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed: String(localized: "Failed to save the license key")
        case .deleteFailed: String(localized: "Failed to delete the saved license key")
        }
    }
}
