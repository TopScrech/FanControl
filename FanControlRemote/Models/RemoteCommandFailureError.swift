import Foundation

struct RemoteCommandFailureError: LocalizedError {
    let message: String?

    var errorDescription: String? {
        message ?? String(localized: "Remote command failed")
    }
}
