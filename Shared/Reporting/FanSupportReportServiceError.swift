import Foundation

enum FanSupportReportServiceError: LocalizedError {
    case ismcExecutableNotFound
    case commandFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .ismcExecutableNotFound:
            "iSMC executable not found"
            
        case .commandFailed(let message):
            message
        }
    }
}
