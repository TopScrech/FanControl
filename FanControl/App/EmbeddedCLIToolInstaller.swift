import Foundation
import OSLog

enum EmbeddedCLIToolInstaller {
    private static let logger = Logger(subsystem: "FanControl", category: "EmbeddedCLIToolInstaller")
    private nonisolated static let executableName = "fan"
    private nonisolated static let managedPathStartMarker = "# >>> FanControl PATH >>>"
    private nonisolated static let managedPathEndMarker = "# <<< FanControl PATH <<<"
    
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
                if existingDestination == bundledExecutableURL {
                    ensureShellPathIncludesInstallDirectoryIfNeeded(installURL.deletingLastPathComponent())
                    return
                }
                
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
            ensureShellPathIncludesInstallDirectoryIfNeeded(installURL.deletingLastPathComponent())
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
        let standardDirectories = [
            URL(filePath: "/usr/local/bin"),
            URL(filePath: "/opt/homebrew/bin"),
            URL.homeDirectory.appending(path: ".local/bin"),
            URL.homeDirectory.appending(path: "bin"),
        ]
        
        let pathDirectories = Set(
            shellPATHDirectories().map {
                $0.standardizedFileURL.path(percentEncoded: false)
            }
        )
        
        let preferredDirectories = standardDirectories.sorted { lhs, rhs in
            let lhsInPath = pathDirectories.contains(lhs.standardizedFileURL.path(percentEncoded: false))
            let rhsInPath = pathDirectories.contains(rhs.standardizedFileURL.path(percentEncoded: false))
            
            if lhsInPath != rhsInPath {
                return lhsInPath && !rhsInPath
            }
            
            return false
        }
        
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
    
    private nonisolated static func shellPATHDirectories() -> [URL] {
        let shellExecutable = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        let environmentPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let loginShellPath = (try? run(
            executableURL: URL(filePath: shellExecutable),
            arguments: ["-lc", "print -r -- \"$PATH\""]
        )) ?? ""
        
        return uniqueDirectories(pathDirectories(from: loginShellPath) + pathDirectories(from: environmentPath))
    }
    
    private nonisolated static func pathDirectories(from path: String) -> [URL] {
        path
            .split(separator: ":")
            .map(String.init)
            .filter { !$0.isEmpty }
            .map { URL(filePath: $0) }
    }
    
    private nonisolated static func uniqueDirectories(_ directories: [URL]) -> [URL] {
        var seenPaths = Set<String>()
        
        return directories.filter {
            seenPaths.insert($0.standardizedFileURL.path(percentEncoded: false)).inserted
        }
    }
    
    private static func ensureShellPathIncludesInstallDirectoryIfNeeded(_ directoryURL: URL) {
        let standardizedDirectory = directoryURL.standardizedFileURL
        let pathDirectories = Set(
            shellPATHDirectories().map {
                $0.standardizedFileURL.path(percentEncoded: false)
            }
        )
        
        guard !pathDirectories.contains(standardizedDirectory.path(percentEncoded: false)) else {
            return
        }
        
        guard let pathExpression = shellPathExpression(for: standardizedDirectory) else {
            Self.logger.error(
                "Skipping PATH update because install directory is unsupported: \(standardizedDirectory.path, privacy: .public)"
            )
            return
        }
        
        do {
            try ensureZshPathConfiguration(pathExpression: pathExpression)
        } catch {
            Self.logger.error("Failed to update zsh PATH for embedded CLI: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    private static func ensureZshPathConfiguration(pathExpression: String) throws {
        let zprofileURL = URL.homeDirectory.appending(path: ".zprofile")
        let existingContents = (try? String(contentsOf: zprofileURL, encoding: .utf8)) ?? ""
        let managedBlock = managedPathBlock(pathExpression: pathExpression)
        let updatedContents: String
        
        if let managedRange = managedPathRange(in: existingContents) {
            let prefix = existingContents[..<managedRange.lowerBound]
            let suffix = existingContents[managedRange.upperBound...]
            updatedContents = String(prefix) + managedBlock + String(suffix)
        } else if existingContents.isEmpty {
            updatedContents = managedBlock
        } else if existingContents.hasSuffix("\n") {
            updatedContents = existingContents + "\n" + managedBlock
        } else {
            updatedContents = existingContents + "\n\n" + managedBlock
        }
        
        guard updatedContents != existingContents else { return }
        
        try createInstallDirectoryIfNeeded(at: zprofileURL.deletingLastPathComponent())
        try updatedContents.write(to: zprofileURL, atomically: true, encoding: .utf8)
        Self.logger.info("Updated zsh PATH configuration for embedded CLI at \(zprofileURL.path, privacy: .public)")
    }
    
    private nonisolated static func shellPathExpression(for directoryURL: URL) -> String? {
        let standardizedDirectory = directoryURL.standardizedFileURL
        let homeDirectory = URL.homeDirectory.standardizedFileURL.path(percentEncoded: false)
        let directoryPath = standardizedDirectory.path(percentEncoded: false)
        
        guard directoryPath.hasPrefix(homeDirectory) else {
            return nil
        }
        
        let relativePath = String(directoryPath.dropFirst(homeDirectory.count))
        let homeRelativePath = (relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !homeRelativePath.isEmpty else { return "$HOME" }
        return "$HOME/\(homeRelativePath)"
    }
    
    private nonisolated static func managedPathBlock(pathExpression: String) -> String {
        """
        \(managedPathStartMarker)
        if [ -d "\(pathExpression)" ]; then
          case ":$PATH:" in
            *":\(pathExpression):"*) ;;
            *) export PATH="\(pathExpression):$PATH" ;;
          esac
        fi
        \(managedPathEndMarker)
        """
    }
    
    private nonisolated static func managedPathRange(in contents: String) -> Range<String.Index>? {
        guard let startRange = contents.range(of: managedPathStartMarker),
              let endRange = contents.range(of: managedPathEndMarker, range: startRange.upperBound..<contents.endIndex)
        else {
            return nil
        }
        
        let afterEndIndex = contents[endRange.upperBound...]
            .firstIndex(where: { $0 != "\n" }) ?? contents.endIndex
        
        return startRange.lowerBound..<afterEndIndex
    }
    
    private nonisolated static func run(executableURL: URL, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        
        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError
        
        try process.run()
        process.waitUntilExit()
        
        let output = String(
            decoding: standardOutput.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )
        
        let errorOutput = String(
            decoding: standardError.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )
        
        guard process.terminationStatus == 0 else {
            throw NSError(
                domain: "EmbeddedCLIToolInstaller",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: errorOutput.trimmingCharacters(in: .whitespacesAndNewlines)]
            )
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private nonisolated static func isManagedZshCompletion(_ contents: String) -> Bool {
        contents.contains(FanShellCompletion.managedHeader)
    }
    
    private nonisolated static func isManagedDestination(_ destinationURL: URL) -> Bool {
        destinationURL.lastPathComponent == executableName && destinationURL.path.contains(".app/Contents/MacOS/")
    }
}
