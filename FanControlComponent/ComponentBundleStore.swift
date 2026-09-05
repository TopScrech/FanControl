import Foundation

@MainActor
final class ComponentBundleStore {
    let directory = URL.applicationSupportDirectory.appending(path: ComponentConfiguration.bundleIdentifier)
    var destination: URL { directory.appending(path: "FanControl Component.app") }

    func isInstalled(_ source: URL) -> Bool {
        source.resolvingSymlinksInPath().standardizedFileURL.path == destination.resolvingSymlinksInPath().standardizedFileURL.path
    }

    func release(at url: URL) throws -> ComponentRelease {
        try ComponentSignature.verify(url)
        guard let bundle = Bundle(url: url),
              let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return try ComponentRelease(version: version, build: build)
    }

    func stage(_ source: URL) throws -> URL {
        let staging = directory.appending(path: "staging-\(UUID().uuidString).app")
        do {
            try FileManager.default.copyItem(at: source, to: staging)
            try ComponentSignature.verify(staging)
            return staging
        } catch {
            try? FileManager.default.removeItem(at: staging)
            throw error
        }
    }

    func replace(with staging: URL) throws {
        let manager = FileManager.default
        let backup = directory.appending(path: "previous-\(UUID().uuidString).app")
        let hadPrevious = manager.fileExists(atPath: destination.path)
        if hadPrevious { try manager.moveItem(at: destination, to: backup) }
        do {
            try manager.moveItem(at: staging, to: destination)
            try ComponentSignature.verify(destination)
        } catch {
            if hadPrevious {
                try? manager.removeItem(at: destination)
                try manager.moveItem(at: backup, to: destination)
            }
            throw error
        }
        // Keep the previous complete signed bundle recoverable if registration later fails
    }

    func startInstalled() throws {
        try ComponentSignature.verify(destination)
        let process = Process()
        process.executableURL = destination.appending(path: "Contents/MacOS/FanControl Component")
        process.currentDirectoryURL = directory
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }
}
