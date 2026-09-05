import AppKit

final class ComponentAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Service operations must run even when macOS restores no SwiftUI windows
        Task { @MainActor in
            let model = ComponentModel.shared
            if CommandLine.arguments.contains("--unregister-for-update") {
                exit(await model.unregisterForUpdate())
            }
            await model.install()
        }
    }
}
