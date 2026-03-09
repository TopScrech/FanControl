import Foundation

enum ISMCCommandError: LocalizedError {
    case executableNotFound,
         commandFailed(String),
         invalidOutput
    
    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            "iSMC executable not found"
            
        case .commandFailed(let message):
            if message.isEmpty {
                "iSMC command failed"
            } else {
                "iSMC command failed: \(message)"
            }
            
        case .invalidOutput:
            "iSMC returned an unrecognized temperature table"
        }
    }
}
