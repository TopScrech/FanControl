import Foundation

enum FanSupportReportServiceError: LocalizedError {
    case executableNotFound(String)
    case commandFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .executableNotFound(let executableName):
            "\(executableName) executable not found"
            
        case .commandFailed(let message):
            message
        }
    }
}
