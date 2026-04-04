import Foundation
import OSLog

enum EmbeddedCLIToolInstaller {
    private static let logger = Logger(subsystem: "FanControl", category: "EmbeddedCLIToolInstaller")
    private nonisolated static let executableName = "fan"
    private nonisolated static let zshCompletionSearchPaths = [
        URL(filePath: "/opt/homebrew/share/zsh/site-functions"),
        URL(filePath: "/usr/local/share/zsh/site-functions"),
    ]
    
    static func installIfNeeded() {
        guard let bundledExecutableURL = bundledExecutableURL else { return }
        installExecutableIfNeeded(at: bundledExecutableURL)
        installZshCompletionIfNeeded()
    }
    
    private static func installExecutableIfNeeded(at bundledExecutableURL: URL) {
        guard let installURL = preferredInstallURL() else {
            Self.logger.error("No writable install directory found for embedded CLI")
            return
        }
        
        do {
            try createInstallDirectoryIfNeeded(at: installURL.deletingLastPathComponent())
            
            if let existingDestination = existingDestinationURL(at: installURL) {
                guard existingDestination != bundledExecutableURL else { return }
                
                if !isManagedDestination(existingDestination) {
                    Self.logger.error(
                        "Skipping CLI install because destination is managed by another tool: \(installURL.path, privacy: .public)"
                    )
                    return
                }
                
                try FileManager.default.removeItem(at: installURL)
            } else if FileManager.default.fileExists(atPath: installURL.path(percentEncoded: false)) {
                Self.logger.error(
                    "Skipping CLI install because destination already exists: \(installURL.path, privacy: .public)"
                )
                return
            }
            
            try FileManager.default.createSymbolicLink(at: installURL, withDestinationURL: bundledExecutableURL)
            Self.logger.info(
                "Installed embedded CLI symlink at \(installURL.path, privacy: .public)"
            )
        } catch {
            Self.logger.error("Failed to install embedded CLI: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private static func installZshCompletionIfNeeded() {
        guard let installURL = preferredZshCompletionInstallURL() else { return }
        
        do {
            try createInstallDirectoryIfNeeded(at: installURL.deletingLastPathComponent())
            
            let script = FanShellCompletion.zshScript()
            
            if let existingScript = try? String(contentsOf: installURL, encoding: .utf8) {
                if existingScript == script {
                    return
                }
                
                guard isManagedZshCompletion(existingScript) else {
                    Self.logger.error(
                        "Skipping zsh completion install because destination is managed by another tool: \(installURL.path, privacy: .public)"
                    )
                    return
                }
            } else if FileManager.default.fileExists(atPath: installURL.path(percentEncoded: false)) {
                Self.logger.error(
                    "Skipping zsh completion install because destination already exists: \(installURL.path, privacy: .public)"
                )
                return
            }
            
            try script.write(to: installURL, atomically: true, encoding: .utf8)
            Self.logger.info(
                "Installed zsh completion at \(installURL.path, privacy: .public)"
            )
        } catch {
            Self.logger.error("Failed to install zsh completion: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private static var bundledExecutableURL: URL? {
        let executableURL = Bundle.main.bundleURL.appending(path: "Contents/MacOS/\(executableName)")
        
        guard FileManager.default.isExecutableFile(atPath: executableURL.path(percentEncoded: false)) else {
            Self.logger.error(
                "Embedded CLI executable is missing: \(executableURL.path, privacy: .public)"
            )
            return nil
        }
        
        return executableURL.standardizedFileURL
    }
    
    private static func preferredInstallURL() -> URL? {
        let preferredDirectories = [
            URL(filePath: "/usr/local/bin"),
            URL(filePath: "/opt/homebrew/bin"),
            URL.homeDirectory.appending(path: ".local/bin"),
            URL.homeDirectory.appending(path: "bin"),
        ]
        
        return preferredInstallDirectory(from: preferredDirectories)?
            .appending(path: executableName)
    }
    
    private static func createInstallDirectoryIfNeeded(at directoryURL: URL) throws {
        if FileManager.default.fileExists(atPath: directoryURL.path(percentEncoded: false)) {
            return
        }
        
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }
    
    private static func existingDestinationURL(at installURL: URL) -> URL? {
        guard let destinationPath = try? FileManager.default.destinationOfSymbolicLink(atPath: installURL.path(percentEncoded: false)) else {
            return nil
        }
        
        let destinationURL = URL(filePath: destinationPath, directoryHint: .notDirectory)
        
        if destinationURL.isFileURL, destinationURL.path.hasPrefix("/") {
            return destinationURL.standardizedFileURL
        }
        
        return installURL.deletingLastPathComponent()
            .appending(path: destinationPath)
            .standardizedFileURL
    }
    
    private static func preferredZshCompletionInstallURL() -> URL? {
        preferredInstallDirectory(from: zshCompletionSearchPaths)?
            .appending(path: FanShellCompletion.zshFilename)
    }
    
    private nonisolated static func preferredInstallDirectory(from directories: [URL]) -> URL? {
        directories.first(where: canInstallFileInside)
    }
    
    private nonisolated static func canInstallFileInside(_ directoryURL: URL) -> Bool {
        let path = directoryURL.path(percentEncoded: false)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: path) {
            return fileManager.isWritableFile(atPath: path)
        }
        
        guard let parentDirectoryURL = nearestExistingDirectory(from: directoryURL) else {
            return false
        }
        
        return fileManager.isWritableFile(atPath: parentDirectoryURL.path(percentEncoded: false))
    }
    
    private nonisolated static func nearestExistingDirectory(from directoryURL: URL) -> URL? {
        let fileManager = FileManager.default
        var candidateURL = directoryURL.standardizedFileURL
        
        while candidateURL.path != "/" {
            if fileManager.fileExists(atPath: candidateURL.path(percentEncoded: false)) {
                return candidateURL
            }
            
            candidateURL.deleteLastPathComponent()
        }
        
        return fileManager.fileExists(atPath: "/") ? URL(filePath: "/") : nil
    }
    
    private nonisolated static func isManagedZshCompletion(_ contents: String) -> Bool {
        contents.contains(FanShellCompletion.managedHeader)
    }
    
    private nonisolated static func isManagedDestination(_ destinationURL: URL) -> Bool {
        destinationURL.lastPathComponent == executableName && destinationURL.path.contains(".app/Contents/MacOS/")
    }
}
