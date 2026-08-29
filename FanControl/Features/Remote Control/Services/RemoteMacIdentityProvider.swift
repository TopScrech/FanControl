import CryptoKit
import Foundation

enum RemoteMacIdentityProvider {
    nonisolated static func identifier() -> String {
        let source = MacDeviceIdentityProvider.deviceIdentifier() ?? ProcessInfo.processInfo.hostName
        
        return SHA256.hash(data: Data(source.utf8)).map {
            let value = String($0, radix: 16)
            return value.count == 1 ? "0\(value)" : value
        }
        .joined()
    }
    
    nonisolated static func name() -> String {
        Host.current().localizedName ?? ProcessInfo.processInfo.hostName
    }
}
