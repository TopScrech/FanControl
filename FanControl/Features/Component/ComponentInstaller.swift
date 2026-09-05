import AppKit
import Observation
import Security

@Observable
@MainActor
final class ComponentInstaller {
    var isInstalling = false
    var status = "Fan control requires additional components"
    var showsInstallPrompt = false
    private var hasPrompted = false

    func promptIfNeeded() {
        guard !hasPrompted else { return }
        hasPrompted = true
        showsInstallPrompt = true
    }

    func install() async {
        guard !isInstalling else { return }
        isInstalling = true
        status = "Preparing components"
        defer { isInstalling = false }
        do {
            // Test distribution only: unpack the signed archive during release packaging
            // Runtime extraction by a sandboxed app creates quarantined executables that
            // LaunchServices cannot launch, even when their signatures are valid
            let app = Bundle.main.bundleURL.appending(path: "Contents/Helpers/FanControl Component.app")
            guard FileManager.default.fileExists(atPath: app.path) else {
                throw Self.failure("This build does not include the component installer")
            }
            try Self.verify(app)
            status = "Installing components — approve any macOS prompts to continue"
            // LaunchServices starts the separately signed installer outside the app sandbox
            // It copies itself to Application Support and registers the bundled daemon
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = true
            _ = try await NSWorkspace.shared.openApplication(at: app, configuration: configuration)
            for _ in 0..<300 {
                if (try? await RemoteSMCService().componentVersion()) != nil {
                    status = "Components installed"
                    return
                }
                try await Task.sleep(for: .seconds(2))
            }
            status = "Installation has not finished — approve the background service in System Settings, or retry"
        } catch {
            let failure = error as NSError
            status = "\(failure.localizedDescription) (\(failure.domain), \(failure.code))"
        }
    }

    private static func verify(_ url: URL) throws {
        var code: SecStaticCode?
        var requirement: SecRequirement?
        let expression = "anchor apple generic and certificate leaf[subject.OU] = \"\(ComponentConfiguration.teamIdentifier)\" and identifier \"\(ComponentConfiguration.bundleIdentifier)\""
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess,
              let code,
              SecRequirementCreateWithString(expression as CFString, [], &requirement) == errSecSuccess,
              let requirement,
              SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate | kSecCSCheckNestedCode | kSecCSCheckAllArchitectures), requirement) == errSecSuccess else {
            throw failure("The component signature could not be verified")
        }
    }

    private static func failure(_ message: String) -> NSError {
        NSError(domain: "ComponentInstallation", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
