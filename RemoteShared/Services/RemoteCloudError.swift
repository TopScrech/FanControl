import Foundation

enum RemoteCloudError: LocalizedError {
    case iCloudUnavailable
    case invalidRecord

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            "Sign in to iCloud to use remote control"
        case .invalidRecord:
            "Remote control data could not be read"
        }
    }
}
