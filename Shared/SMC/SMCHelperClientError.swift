import Foundation

nonisolated enum SMCHelperClientError: LocalizedError {
    case invalidProxy, remoteError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidProxy:
            String(localized: "SMC helper connection unavailable")
            
        case .remoteError(let message):
            message
        }
    }
}
