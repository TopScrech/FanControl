import Foundation

@MainActor
final class ComponentRegistration {
    private var isRunning = false

    func run(driver: any ComponentRegistrationDriver, attempts: Int = 180, changed: (ComponentInstallPhase) -> Void) async throws {
        guard !isRunning else { throw Self.failure("Installation is already running") }
        isRunning = true
        defer { isRunning = false }
        var openedSettings = false
        var lastError: Error?
        for _ in 0..<attempts {
            try Task.checkCancellation()
            var registrationNeedsApproval = false
            if driver.state != .enabled {
                do { try driver.register() }
                catch {
                    guard Self.isPendingApproval(error, state: driver.state) else { throw error }
                    lastError = error
                    registrationNeedsApproval = true
                }
            }
            if registrationNeedsApproval || driver.state == .requiresApproval {
                changed(.waitingForApproval)
                if !openedSettings {
                    driver.openApprovalSettings()
                    openedSettings = true
                }
            } else {
                changed(.connecting)
                do {
                    try await driver.handshake()
                    changed(.ready)
                    return
                } catch { lastError = error }
            }
            try await driver.pause()
        }
        let detail = lastError.map { " — \(($0 as NSError).domain) \(($0 as NSError).code): \($0.localizedDescription)" } ?? ""
        throw Self.failure("Component registration timed out in state \(driver.state)\(detail)")
    }

    static func isPendingApproval(_ error: Error, state: ComponentServiceState) -> Bool {
        // EPERM can precede requiresApproval after replacement on macOS
        // Only known authorization domains/codes in recoverable service states qualify
        guard state == .requiresApproval || state == .notRegistered else { return false }
        let error = error as NSError
        if error.domain == NSPOSIXErrorDomain { return error.code == Int(EPERM) }
        return error.domain == "SMAppServiceErrorDomain" && [1, 4, 11, 12].contains(error.code)
    }

    static func prepareReplacement(state: ComponentServiceState, restore: () async throws -> Void, unregister: () async throws -> Void) async throws {
        // Never use a successful version probe as the condition for safety restoration
        // Enabled registration may represent a running helper even if its handshake fails
        if state == .enabled { try await restore() }
        if state == .enabled || state == .requiresApproval { try await unregister() }
    }

    private static func failure(_ description: String) -> NSError {
        NSError(domain: "ComponentRegistration", code: 1, userInfo: [NSLocalizedDescriptionKey: description])
    }
}
