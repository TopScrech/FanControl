import AppKit
import Observation

@Observable
@MainActor
final class ComponentInstaller {
    var phase = ComponentInstallPhase.unavailable
    var isInstalling = false
    private(set) var generation = 0
    var status = "Fan control requires additional components"
    var showsInstallPrompt = false
    private var hasPrompted = false

    func promptIfNeeded() {
        guard !hasPrompted, !isInstalling else { return }
        hasPrompted = true
        showsInstallPrompt = true
    }

    func install() async {
        guard !isInstalling else { return }
        hasPrompted = true
        generation += 1
        isInstalling = true
        phase = .installing
        var stage = "Verifying bundled installer"
        status = stage
        defer { isInstalling = false }
        do {
            let app = Bundle.main.bundleURL.appending(path: "Contents/Helpers/FanControl Component.app")
            try ComponentSignature.verify(app)
            stage = "Launching installer"
            status = "Installing components — follow the macOS approval prompts"
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = true
            _ = try await NSWorkspace.shared.openApplication(at: app, configuration: configuration)
            phase = .connecting
            stage = "Connecting to helper"
            let deadline = ContinuousClock.now.advanced(by: .seconds(600))
            var lastError: Error?
            while ContinuousClock.now < deadline {
                try Task.checkCancellation()
                do {
                    let version = try await RemoteSMCService().componentVersion()
                    guard version.compare(ComponentConfiguration.version, options: .numeric) != .orderedAscending else {
                        throw NSError(domain: "ComponentInstallation", code: 3, userInfo: [NSLocalizedDescriptionKey: "Waiting for the updated helper to start"])
                    }
                    phase = .ready
                    status = "Components connected"
                    return
                } catch { lastError = error }
                // The installer owns authoritative approval status outside the sandbox
                phase = .waitingForApproval
                status = "Waiting for the component — complete any approval shown by the installer"
                try await Task.sleep(for: .seconds(2))
            }
            throw lastError ?? NSError(domain: "ComponentInstallation", code: 2, userInfo: [NSLocalizedDescriptionKey: "The installer did not finish — check its window and retry"])
        } catch {
            phase = .failed
            let error = error as NSError
            status = "\(stage): \(error.localizedDescription) (\(error.domain), \(error.code))"
        }
    }
}
