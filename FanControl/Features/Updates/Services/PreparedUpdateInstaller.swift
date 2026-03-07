import Foundation
import AutoUpdate

struct PreparedUpdateInstaller {
    enum InstallError: LocalizedError {
        case invalidBundle
        
        var errorDescription: String? {
            switch self {
            case .invalidBundle:
                String(localized: "Downloaded update is invalid")
            }
        }
    }
    
    func install(_ preparedUpdate: PreparedUpdate) throws {
        guard Bundle(url: preparedUpdate.bundleURL) != nil else {
            throw InstallError.invalidBundle
        }
        
        let fileManager = FileManager.default
        let installedBundleURL = Bundle.main.bundleURL
        
        try fileManager.removeItem(at: installedBundleURL)
        try fileManager.moveItem(at: preparedUpdate.bundleURL, to: installedBundleURL)
        try? fileManager.removeItem(at: preparedUpdate.temporaryDirectoryURL)
    }
}
