import AppKit
import Security

@_silgen_name("SecTranslocateCreateOriginalPathForURL")
private func secTranslocateCreateOriginalPathForURL(
    _ translocatedPath: CFURL,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Unmanaged<CFURL>?

@MainActor
enum AppDownloadsMovePrompter {
    static func promptIfNeeded() {
        guard isRunningFromDownloads else { return }
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        let messageText = destinationAppExists
        ? String(localized: "Replace the copy in /Applications?")
        : String(localized: "Move FanControl to /Applications?")
        
        let informativeText = destinationAppExists
        ? String(localized: "FanControl is running from Downloads. Move it to /Applications and replace the existing copy so the helper can install correctly")
        : String(localized: "FanControl is running from Downloads. Move it to /Applications so the helper can install correctly")
        
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = messageText
        alert.informativeText = informativeText
        alert.addButton(withTitle: String(localized: "Move to Applications"))
        alert.addButton(withTitle: String(localized: "Not now"))
        
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        
        moveToApplicationsAndRelaunch()
    }
    
    private static var runningBundleURL: URL {
        Bundle.main.bundleURL.standardizedFileURL.resolvingSymlinksInPath()
    }
    
    private static var sourceBundleURL: URL {
        var error: Unmanaged<CFError>?
        guard let originalURL = secTranslocateCreateOriginalPathForURL(
            runningBundleURL as CFURL,
            &error
        )?.takeRetainedValue() as URL? else {
            return runningBundleURL
        }
        
        return originalURL.standardizedFileURL.resolvingSymlinksInPath()
    }
    
    private static var destinationURL: URL {
        URL(filePath: "/Applications").appending(path: sourceBundleURL.lastPathComponent)
    }
    
    private static var isRunningFromDownloads: Bool {
        let downloadsURL = URL.downloadsDirectory.standardizedFileURL.resolvingSymlinksInPath()
        return sourceBundleURL.pathComponents.starts(with: downloadsURL.pathComponents)
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
        
        guard sourceBundleURL != destinationURL else {
            return destinationURL
        }
        
        if destinationAppExists {
            let resultingURL = try fileManager.replaceItemAt(
                destinationURL,
                withItemAt: sourceBundleURL,
                backupItemName: nil,
                options: []
            )
            
            return resultingURL?.standardizedFileURL ?? destinationURL
        }
        
        try fileManager.moveItem(at: sourceBundleURL, to: destinationURL)
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
        alert.messageText = String(localized: "Couldn’t move FanControl to /Applications")
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: String(localized: "OK"))
        alert.runModal()
    }
}
