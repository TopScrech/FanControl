import Foundation
import OSLog

enum EmbeddedCLIToolInstaller {
    private static let logger = Logger(subsystem: "FanControl", category: "EmbeddedCLIToolInstaller")
    private static let executableName = "fan"

    static func installIfNeeded() {
        guard let bundledExecutableURL = bundledExecutableURL else { return }
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
        let fileManager = FileManager.default
        let preferredDirectories = [
            URL(filePath: "/usr/local/bin"),
            URL(filePath: "/opt/homebrew/bin"),
            URL.homeDirectory.appending(path: ".local/bin"),
            URL.homeDirectory.appending(path: "bin"),
        ]

        for directoryURL in preferredDirectories {
            let path = directoryURL.path(percentEncoded: false)

            if fileManager.fileExists(atPath: path) {
                if fileManager.isWritableFile(atPath: path) {
                    return directoryURL.appending(path: executableName)
                }

                continue
            }

            if isUserOwnedDirectory(directoryURL) {
                return directoryURL.appending(path: executableName)
            }
        }

        return nil
    }

    private static func createInstallDirectoryIfNeeded(at directoryURL: URL) throws {
        guard isUserOwnedDirectory(directoryURL) else { return }

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

    private static func isManagedDestination(_ destinationURL: URL) -> Bool {
        destinationURL.lastPathComponent == executableName && destinationURL.path.contains(".app/Contents/MacOS/")
    }

    private static func isUserOwnedDirectory(_ directoryURL: URL) -> Bool {
        let homeDirectoryPath = URL.homeDirectory.standardizedFileURL.path(percentEncoded: false)
        let directoryPath = directoryURL.standardizedFileURL.path(percentEncoded: false)
        return directoryPath == homeDirectoryPath || directoryPath.hasPrefix("\(homeDirectoryPath)/")
    }
}
