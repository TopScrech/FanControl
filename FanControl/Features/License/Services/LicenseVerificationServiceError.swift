import Foundation

enum LicenseVerificationServiceError: LocalizedError {
    case invalidResponse
    case invalidPayload(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            String(localized: "License check failed due to an invalid server response")
        case .invalidPayload:
            String(localized: "License check failed due to an invalid server payload")
        }
    }
}
