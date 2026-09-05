import Foundation
#if !SANDBOXED_APP
import CoreSMC
#endif

// The connection is configured once; XPC manages concurrent sends and invalidation
nonisolated final class RemoteSMCService: SMCService, @unchecked Sendable {
    private let connection: NSXPCConnection

    init(onDisconnect: @escaping @Sendable () -> Void = {}) {
        connection = NSXPCConnection(
            machServiceName: FanControlXPCConstants.machServiceName,
            options: .privileged
        )
        connection.setCodeSigningRequirement(ComponentConfiguration.helperRequirement)
        connection.remoteObjectInterface = FanControlXPCInterface.make()
        connection.interruptionHandler = onDisconnect
        connection.invalidationHandler = onDisconnect
        connection.resume()
    }

    deinit { connection.invalidate() }

    func componentVersion() async throws -> String {
        try await request { proxy, reply in
            proxy.componentInfo { version, description in
                guard version == ComponentConfiguration.protocolVersion else {
                    reply.finish(.failure(SMCHelperClientError.remoteError("Update FanControl and its component to compatible versions")))
                    return
                }
                reply.finish(.success(description))
            }
        }
    }

    func readTemperatureOutput() async throws -> String {
        try await request { proxy, reply in
            proxy.readTemperatures { output, error in
                if let error { reply.finish(.failure(SMCHelperClientError.remoteError(error))) }
                else if let output { reply.finish(.success(output)) }
                else { reply.finish(.failure(SMCHelperClientError.remoteError("Component returned no temperatures"))) }
            }
        }
    }

    func prepareForUpdate() async throws {
        try await requestVoid { $0.prepareForUpdate(withReply: $1) }
    }

    func readFans() async throws -> [Fan] {
        try await request { proxy, reply in
            proxy.readFans { snapshots, error in
                if let error { reply.finish(.failure(SMCHelperClientError.remoteError(error))) }
                else if let snapshots { reply.finish(.success(snapshots.map(Fan.init(snapshot:)))) }
                else { reply.finish(.failure(SMCHelperClientError.remoteError("Component returned no fans"))) }
            }
        }
    }

    func setFanManualRPM(fanID: Int, rpm: Double) async throws {
        try await requestVoid { $0.setManualRPM(fanID: fanID, rpm: rpm, withReply: $1) }
    }

    func setFanAuto(fanID: Int) async throws {
        try await requestVoid { $0.setAuto(fanID: fanID, withReply: $1) }
    }

    func keepAliveManualOverride() async throws {
        try await requestVoid { $0.keepAliveManualOverride(withReply: $1) }
    }

    private func requestVoid(_ work: @Sendable (FanControlXPCProtocol, @escaping @Sendable (String?) -> Void) -> Void) async throws {
        let _: Void = try await request { proxy, reply in
            work(proxy) { error in
                if let error { reply.finish(.failure(SMCHelperClientError.remoteError(error))) }
                else { reply.finish(.success(())) }
            }
        }
    }

    private func request<Value: Sendable>(_ work: @Sendable (FanControlXPCProtocol, XPCReply<Value>) -> Void) async throws -> Value {
        let reply = XPCReply<Value>()
        let deadline = Task {
            do {
                try await Task.sleep(for: .seconds(5))
                reply.finish(.failure(SMCHelperClientError.remoteError("FanControl Component did not respond")))
            } catch {}
        }
        defer { deadline.cancel() }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                reply.install(continuation)
                guard !Task.isCancelled else {
                    reply.finish(.failure(CancellationError()))
                    return
                }
                let proxy = connection.remoteObjectProxyWithErrorHandler {
                    reply.finish(.failure($0))
                } as? FanControlXPCProtocol
                guard let proxy else {
                    reply.finish(.failure(SMCHelperClientError.invalidProxy))
                    return
                }
                work(proxy, reply)
            }
        } onCancel: {
            reply.finish(.failure(CancellationError()))
        }
    }
}
