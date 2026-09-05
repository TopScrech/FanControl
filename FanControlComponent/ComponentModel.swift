import AppKit
import Observation

@Observable
@MainActor
final class ComponentModel {
    static let shared = ComponentModel()
    var phase = ComponentInstallPhase.installing
    var status = "Preparing component installation"
    var isBusy = false
    var needsApproval: Bool { phase == .waitingForApproval }
    var isFinished: Bool { phase == .ready }
    private let bundles = ComponentBundleStore()
    private let registration = ComponentRegistration()
    private let driver = ComponentServiceRegistration()

    func install() async {
        guard !isBusy, !isFinished else { return }
        isBusy = true
        defer { isBusy = false }
        var stage = "Acquiring installation lock"
        do {
            try FileManager.default.createDirectory(at: bundles.directory, withIntermediateDirectories: true)
            // A child launched during handoff waits for its parent to release this lock
            var lock: ComponentInstallLock?
            for _ in 0..<30 {
                do { lock = try ComponentInstallLock(directory: bundles.directory); break }
                catch {
                    guard (error as NSError).code == Int(EWOULDBLOCK) else { throw error }
                    try await Task.sleep(for: .seconds(1))
                }
            }
            guard let lock else { throw NSError(domain: "ComponentInstallation", code: 5, userInfo: [NSLocalizedDescriptionKey: "Another installation is still running — retry after it finishes"]) }
            defer { withExtendedLifetime(lock) {} }
            stage = "Verifying component"
            let source = Bundle.main.bundleURL
            let incoming = try bundles.release(at: source)
            if !bundles.isInstalled(source) {
                var replace = true
                if FileManager.default.fileExists(atPath: bundles.destination.path) {
                    let installed = try bundles.release(at: bundles.destination)
                    // Same release preserves registration; a newer installed release wins
                    replace = installed < incoming
                }
                if replace {
                    phase = .installing
                    stage = "Staging component"
                    let staged = try bundles.stage(source)
                    defer { try? FileManager.default.removeItem(at: staged) }
                    stage = "Restoring automatic fan control"
                    try await driver.prepareReplacement()
                    stage = "Replacing component bundle"
                    try bundles.replace(with: staged)
                }
                stage = "Launching installed component"
                try bundles.startInstalled()
                NSApplication.shared.terminate(nil)
                return
            }
            stage = "Registering component"
            try await registration.run(driver: driver) { phase in
                self.phase = phase
                switch phase {
                case .waitingForApproval: self.status = "Allow FanControl Component in Login Items & Extensions to finish installation"
                case .ready: self.status = "Components installed and connected"
                default: self.status = "Connecting to the fan control helper"
                }
            }
            NSApplication.shared.terminate(nil)
        } catch {
            phase = .failed
            let error = error as NSError
            status = "\(stage) [\(driver.state)]: \(error.localizedDescription) (\(error.domain), \(error.code))"
        }
    }

    func openApprovalSettings() { driver.openApprovalSettings() }
}
