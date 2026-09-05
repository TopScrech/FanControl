import AppKit

final class ComponentAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Installation must start even when no SwiftUI window is restored
        Task { @MainActor in await ComponentModel.shared.install() }
    }
}
