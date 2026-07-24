import Foundation

enum RemoteControlHostError: LocalizedError {
    case fanUnavailable, helperUnavailable
    
    var errorDescription: String? {
        switch self {
        case .fanUnavailable: "The selected fan is no longer available"
        case .helperUnavailable: "The privileged helper is not available"
        }
    }
}
