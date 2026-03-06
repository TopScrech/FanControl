import AppKit

@MainActor
enum AppDownloadsMovePrompter {
    static func promptIfNeeded() {
        guard isRunningFromDownloads else { return }

        NSApplication.shared.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = destinationAppExists
            ? "Replace the copy in /Applications?"
            : "Move FanControl to /Applications?"
        alert.informativeText = destinationAppExists
            ? "FanControl is running from Downloads. Move it to /Applications and replace the existing copy so the helper can install correctly"
            : "FanControl is running from Downloads. Move it to /Applications so the helper can install correctly"
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Not Now")

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        moveToApplicationsAndRelaunch()
    }

    private static var bundleURL: URL {
        Bundle.main.bundleURL.standardizedFileURL.resolvingSymlinksInPath()
    }

    private static var destinationURL: URL {
        URL(filePath: "/Applications").appending(path: bundleURL.lastPathComponent)
    }

    private static var isRunningFromDownloads: Bool {
        let downloadsURL = URL.downloadsDirectory.standardizedFileURL.resolvingSymlinksInPath()
        return bundleURL.pathComponents.starts(with: downloadsURL.pathComponents)
    }

    private static var destinationAppExists: Bool {
        FileManager.default.fileExists(atPath: destinationURL.path(percentEncoded: false))
    }

    private static func moveToApplicationsAndRelaunch() {
        do {
            let installedAppURL = try installApp()
            try relaunchApp(at: installedAppURL)
            NSApplication.shared.terminate(nil)
        } catch {
            presentMoveFailureAlert(for: error)
        }
    }

    private static func installApp() throws -> URL {
        let fileManager = FileManager.default

        guard bundleURL != destinationURL else {
            return destinationURL
        }

        if destinationAppExists {
            let resultingURL = try fileManager.replaceItemAt(
                destinationURL,
                withItemAt: bundleURL,
                backupItemName: nil,
                options: []
            )

            return resultingURL?.standardizedFileURL ?? destinationURL
        }

        try fileManager.moveItem(at: bundleURL, to: destinationURL)
        return destinationURL
    }

    private static func relaunchApp(at installedAppURL: URL) throws {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/open")
        process.arguments = [installedAppURL.path(percentEncoded: false)]
        try process.run()
    }

    private static func presentMoveFailureAlert(for error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Couldn’t move FanControl to /Applications"
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
