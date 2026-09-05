import Foundation

@MainActor
protocol ComponentRegistrationDriver {
    var state: ComponentServiceState { get }
    func register() throws
    func handshake() async throws
    func openApprovalSettings()
    func pause() async throws
}
