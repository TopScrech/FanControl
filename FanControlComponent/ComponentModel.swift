import AppKit
import Observation
import Security
import ServiceManagement

@Observable
@MainActor
final class ComponentModel {
    static let shared = ComponentModel()
    var status = "Installing components"
    var isBusy = false
    var needsApproval = false
    var isFinished = false

    private var service: SMAppService {
        .daemon(plistName: FanControlXPCConstants.launchdPlistName)
    }

    func install() async {
        guard !isBusy, !isFinished else { return }
        isBusy = true
        needsApproval = false
        defer { isBusy = false }
        do {
            let manager = FileManager.default
            let directory = URL.applicationSupportDirectory.appending(path: ComponentConfiguration.bundleIdentifier)
            let destination = directory.appending(path: "FanControl Component.app")
            if Bundle.main.bundleURL.resolvingSymlinksInPath().path != destination.resolvingSymlinksInPath().path {
                try manager.createDirectory(at: directory, withIntermediateDirectories: true)
                // Ask the installed version to restore automatic fan control and unregister
                // from its own bundle before replacing any files used by launchd
                if manager.fileExists(atPath: destination.path) {
                    try Self.verifyInstalledComponent(destination)
                    guard let version = Bundle(url: destination)?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
                          version.compare("1.1", options: .numeric) != .orderedAscending else {
                        throw NSError(domain: "ComponentInstallation", code: 3, userInfo: [NSLocalizedDescriptionKey: "Stop the older component from its window before removing it and retrying installation"])
                    }
                    if version == ComponentConfiguration.version {
                        try Self.startInstalledComponent(destination, directory: directory)
                        NSApplication.shared.terminate(nil)
                        return
                    }
                    // The Mach service label identifies the registration across app versions
                    // Unregister here rather than launching an old GUI just to run cleanup
                    if (try? await RemoteSMCService().componentVersion()) != nil {
                        try await RemoteSMCService().prepareForUpdate()
                    }
                    if service.status == .enabled || service.status == .requiresApproval {
                        try await service.unregister()
                    }
                }
                let staging = directory.appending(path: UUID().uuidString + ".app")
                try manager.copyItem(at: Bundle.main.bundleURL, to: staging)
                if manager.fileExists(atPath: destination.path) {
                    _ = try manager.replaceItemAt(destination, withItemAt: staging)
                } else {
                    try manager.moveItem(at: staging, to: destination)
                }
                // The user has already launched this signed installer through LaunchServices
                // Launch the verified installed executable directly so LaunchServices does not
                // try to recycle a still-mounted App Translocation image (OSStatus -47)
                try Self.startInstalledComponent(destination, directory: directory)
                NSApplication.shared.terminate(nil)
                return
            }
            if service.status != .enabled && service.status != .requiresApproval {
                do {
                    try service.register()
                } catch {
                    // macOS can return EPERM after recording a daemon that needs approval
                    // Treat that state as pending user approval rather than failed installation
                    guard service.status == .requiresApproval || (error as NSError).code == EPERM else { throw error }
                    needsApproval = true
                }
            }
            needsApproval = needsApproval || service.status == .requiresApproval
            if needsApproval {
                status = "Allow FanControl Component in System Settings to finish installation"
                SMAppService.openSystemSettingsLoginItems()
            }
            // Reconnect automatically after the user grants the macOS background-service approval
            for _ in 0..<300 {
                // Background approval can leave an earlier failed registration disabled
                // Retry registration until launchd accepts it, without unregistering again
                if service.status != .enabled {
                    do { try service.register() } catch {
                        if (error as NSError).code != EPERM && service.status != .requiresApproval {
                            throw error
                        }
                    }
                }
                if service.status == .enabled,
                   (try? await RemoteSMCService().componentVersion()) != nil {
                    isFinished = true
                    status = "Components installed"
                    NSApplication.shared.terminate(nil)
                    return
                }
                try await Task.sleep(for: .seconds(3))
            }
            status = "Installation is waiting for background-service approval — allow FanControl Component in System Settings, then retry"
        } catch {
            status = "Installation could not finish: \(error.localizedDescription)"
        }
    }

    func unregisterForUpdate() async -> Int32 {
        do {
            if service.status == .enabled {
                try await RemoteSMCService().prepareForUpdate()
            }
            if service.status == .enabled || service.status == .requiresApproval { try await service.unregister() }
            return 0
        } catch { return 1 }
    }

    private static func startInstalledComponent(_ destination: URL, directory: URL) throws {
        try verifyInstalledComponent(destination)
        let process = Process()
        process.executableURL = destination.appending(path: "Contents/MacOS/FanControl Component")
        process.currentDirectoryURL = directory
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }

    private static func verifyInstalledComponent(_ url: URL) throws {
        var code: SecStaticCode?
        var requirement: SecRequirement?
        let expression = "anchor apple generic and certificate leaf[subject.OU] = \"8FQUA2F388\" and identifier \"dev.topscrech.FanControl.component\""
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess,
              let code,
              SecRequirementCreateWithString(expression as CFString, [], &requirement) == errSecSuccess,
              let requirement,
              SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate | kSecCSCheckNestedCode | kSecCSCheckAllArchitectures), requirement) == errSecSuccess else {
            throw NSError(domain: "ComponentInstallation", code: 4, userInfo: [NSLocalizedDescriptionKey: "The installed component signature is invalid"])
        }
    }

    func openApprovalSettings() { SMAppService.openSystemSettingsLoginItems() }
}
