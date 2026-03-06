import Foundation

enum LicenseVerificationServiceError: LocalizedError {
    case invalidResponse
    case invalidPayload(statusCode: Int)
    case serverMessage(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            String(localized: "License check failed due to an invalid server response")
        case .invalidPayload:
            String(localized: "License check failed due to an invalid server payload")
        case .serverMessage(let message):
            message
        }
    }
}
