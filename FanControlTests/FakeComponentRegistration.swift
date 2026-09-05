import Foundation

@MainActor
final class FakeComponentRegistration: ComponentRegistrationDriver {
    var state = ComponentServiceState.notRegistered
    var registrationCount = 0
    var pendingPermissionErrors = 0
    var handshakeCount = 0
    var settingsCount = 0
    var pauseCount = 0
    var approvalOnNextPause = false
    var pauseAction: (() async throws -> Void)?

    func register() throws {
        registrationCount += 1
        if pendingPermissionErrors > 0 {
            pendingPermissionErrors -= 1
            throw NSError(domain: "SMAppServiceErrorDomain", code: 1)
        }
        if state == .requiresApproval {
            throw NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM))
        }
        state = .enabled
    }
    func handshake() async throws { handshakeCount += 1 }
    func openApprovalSettings() { settingsCount += 1 }
    func pause() async throws {
        pauseCount += 1
        if approvalOnNextPause { state = .notRegistered }
        try await pauseAction?()
    }
}
