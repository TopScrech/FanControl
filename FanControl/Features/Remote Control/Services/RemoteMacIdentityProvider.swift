import CryptoKit
import Foundation

enum RemoteMacIdentityProvider {
    // A container-local identifier avoids hardware UUID access in the sandbox
    nonisolated private static let installationID: String = {
        let defaults = UserDefaults.standard
        let key = "remoteControlInstallationID"
        if let saved = defaults.string(forKey: key) { return saved }
        let value = UUID().uuidString
        defaults.set(value, forKey: key)
        return value
    }()

    nonisolated static func identifier() -> String {
        let source = installationID
        
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
