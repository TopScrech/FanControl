import ServiceManagement

@MainActor
final class ComponentServiceRegistration: ComponentRegistrationDriver {
    let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)

    var state: ComponentServiceState {
        switch service.status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notRegistered: .notRegistered
        default: .notFound
        }
    }

    func register() throws { try service.register() }
    func handshake() async throws {
        let version = try await RemoteSMCService().componentVersion()
        guard version.compare(ComponentConfiguration.version, options: .numeric) != .orderedAscending else {
            throw NSError(domain: "ComponentRegistration", code: 2, userInfo: [NSLocalizedDescriptionKey: "Waiting for the replacement helper to start"])
        }
    }
    func pause() async throws { try await Task.sleep(for: .seconds(2)) }
    func openApprovalSettings() { SMAppService.openSystemSettingsLoginItems() }

    func prepareReplacement() async throws {
        let client = RemoteSMCService()
        // Probe a registered or responsive daemon, and fail closed for enabled services
        let responsive = (try? await client.componentVersion()) != nil
        try await ComponentRegistration.prepareReplacement(
            state: responsive ? .enabled : state,
            restore: { try await client.prepareForUpdate() },
            unregister: { try await self.service.unregister() }
        )
    }
}
