import Foundation

struct FanCLIError: LocalizedError {
    let message: String
    let exitCode: Int32
    
    var errorDescription: String? {
        message
    }
}

extension FanCLIError {
    static func usage(_ message: String) -> Self {
        Self(message: message, exitCode: 64)
    }
    
    static func failure(_ message: String, exitCode: Int32 = 1) -> Self {
        Self(message: message, exitCode: exitCode)
    }
}
