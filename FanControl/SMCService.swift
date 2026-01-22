import Foundation
import OSLog
import ServiceManagement

protocol SMCService {
    func readFans() async throws -> [Fan]
    func setFanManualRPM(fanID: Int, rpm: Double) async throws
    func setFanAuto(fanID: Int) async throws
    func keepAliveManualOverride() async throws
}

final class LocalSMCService: SMCService {
    private let smc: SMCClient
    
    init() throws {
        smc = try SMCClient()
    }
    
    func readFans() async throws -> [Fan] {
        try smc.readFans()
    }
    
    func setFanManualRPM(fanID: Int, rpm: Double) async throws {
        try smc.setFanManualRPM(fanID: fanID, rpm: rpm)
    }
    
    func setFanAuto(fanID: Int) async throws {
        try smc.setFanAuto(fanID: fanID)
    }
    
    func keepAliveManualOverride() async throws {
        try smc.keepAliveManualOverride()
    }
}

enum SMCHelperClientError: LocalizedError {
    case invalidProxy
    case remoteError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidProxy:
            "SMC helper connection unavailable"
        case .remoteError(let message):
            message
        }
    }
}

final class RemoteSMCService: SMCService {
    private static let logger = Logger(subsystem: "FanControl", category: "SMCHelperClient")
    private let connection: NSXPCConnection
    
    init() {
        connection = NSXPCConnection(
            machServiceName: FanControlXPCConstants.machServiceName,
            options: .privileged
        )
        connection.remoteObjectInterface = FanControlXPCInterface.make()
        connection.interruptionHandler = {
            Self.logger.error("SMC helper connection interrupted")
        }
        connection.invalidationHandler = {
            Self.logger.info("SMC helper connection invalidated")
        }
        connection.resume()
    }
    
    deinit {
        connection.invalidate()
    }
    
    func readFans() async throws -> [Fan] {
        try await withProxy { proxy, finish in
            let lock = NSLock()
            var finished = false
            func finishOnce(_ result: Result<[Fan], Error>) {
                lock.lock()
                defer { lock.unlock() }
                guard !finished else { return }
                finished = true
                finish(result)
            }

            Self.logger.info("Remote readFans request")
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                finishOnce(.failure(SMCHelperClientError.remoteError("SMC helper readFans timeout")))
            }
            proxy.readFans { snapshots, error in
                if let error {
                    finishOnce(.failure(SMCHelperClientError.remoteError(error)))
                    return
                }
                
                let fans = (snapshots ?? []).map(Fan.init(snapshot:))
                Self.logger.info("Remote readFans count=\(fans.count, privacy: .public)")
                finishOnce(.success(fans))
            }
        }
    }
    
    func setFanManualRPM(fanID: Int, rpm: Double) async throws {
        try await withProxyVoid { proxy, finish in
            proxy.setManualRPM(fanID: fanID, rpm: rpm) { error in
                if let error {
                    finish(.failure(SMCHelperClientError.remoteError(error)))
                } else {
                    finish(.success(()))
                }
            }
        }
    }
    
    func setFanAuto(fanID: Int) async throws {
        try await withProxyVoid { proxy, finish in
            proxy.setAuto(fanID: fanID) { error in
                if let error {
                    finish(.failure(SMCHelperClientError.remoteError(error)))
                } else {
                    finish(.success(()))
                }
            }
        }
    }
    
    func keepAliveManualOverride() async throws {
        try await withProxyVoid { proxy, finish in
            proxy.keepAliveManualOverride { error in
                if let error {
                    finish(.failure(SMCHelperClientError.remoteError(error)))
                } else {
                    finish(.success(()))
                }
            }
        }
    }
    
    private func withProxy<T>(
        _ work: @escaping (FanControlXPCProtocol, @escaping (Result<T, Error>) -> Void) -> Void
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            var finished = false
            
            func finish(_ result: Result<T, Error>) {
                guard !finished else { return }
                finished = true
                continuation.resume(with: result)
            }
            
            func finishOnMain(_ result: Result<T, Error>) {
                Task { @MainActor in
                    finish(result)
                }
            }
            
            let proxy = connection.remoteObjectProxyWithErrorHandler { error in
                Self.logger.error("SMC helper XPC error: \(error.localizedDescription, privacy: .public)")
                finishOnMain(.failure(error))
            } as? FanControlXPCProtocol
            
            guard let proxy else {
                finish(.failure(SMCHelperClientError.invalidProxy))
                return
            }
            
            work(proxy, finishOnMain)
        }
    }

    private func withProxyVoid(
        _ work: @escaping (FanControlXPCProtocol, @escaping (Result<Void, Error>) -> Void) -> Void
    ) async throws {
        _ = try await withProxy(work)
    }
}

struct SMCHelperInstaller {
    private static let logger = Logger(subsystem: "FanControl", category: "SMCHelperInstaller")
    
    static func registerIfNeeded() throws -> SMAppService.Status {
        let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)
        
        if service.status == .enabled {
            return service.status
        }
        
        do {
            try service.register()
        } catch {
            let nsError = error as NSError
            Self.logger.error("Helper register failed: \(nsError.domain, privacy: .public) code=\(nsError.code) \(nsError.localizedDescription, privacy: .public)")
            throw error
        }
        
        return service.status
    }
}
