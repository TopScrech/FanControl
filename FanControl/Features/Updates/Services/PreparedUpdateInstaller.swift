import Foundation
import AutoUpdate

struct PreparedUpdateInstaller {
    enum InstallError: LocalizedError {
        case invalidBundle, invalidCodeSignature(String?)
        
        var errorDescription: String? {
            switch self {
            case .invalidBundle:
                String(localized: "Downloaded update is invalid")
                
            case .invalidCodeSignature(let details):
                if let details, !details.isEmpty {
                    String(localized: "Downloaded update failed code signing validation: \(details)")
                } else {
                    String(localized: "Downloaded update failed code signing validation")
                }
            }
        }
    }
    
    func install(_ preparedUpdate: PreparedUpdate) throws -> URL {
        try removeAppleDoubleFiles(in: preparedUpdate.bundleURL)
        
        guard let bundle = Bundle(url: preparedUpdate.bundleURL) else {
            throw InstallError.invalidBundle
        }
        
        try validateCodeSignature(for: bundle.bundleURL)
        
        let fm = FileManager.default
        let installedBundleURL = Bundle.main.bundleURL
        
        try fm.removeItem(at: installedBundleURL)
        try fm.moveItem(at: preparedUpdate.bundleURL, to: installedBundleURL)
        try? fm.removeItem(at: preparedUpdate.temporaryDirectoryURL)
        
        return installedBundleURL
    }
    
    private func removeAppleDoubleFiles(in bundleURL: URL) throws {
        let enumerator = FileManager.default.enumerator(
            at: bundleURL,
            includingPropertiesForKeys: [.isRegularFileKey]
        )
        
        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.lastPathComponent.hasPrefix("._") else { continue }
            try FileManager.default.removeItem(at: fileURL)
        }
    }
    
    private func validateCodeSignature(for bundleURL: URL) throws {
        let process = Process()
        let errorPipe = Pipe()
        
        process.executableURL = URL(filePath: "/usr/bin/codesign")
        process.arguments = ["--verify", "--deep", "--strict", "--verbose=2", bundleURL.path]
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            let details = String(decoding: errorPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            throw InstallError.invalidCodeSignature(details.isEmpty ? nil : details)
        }
    }
}
