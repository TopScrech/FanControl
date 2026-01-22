import Foundation
import OSLog

final class FanControlHelperService: NSObject, FanControlXPCProtocol {
    private static let logger = Logger(subsystem: "FanControl", category: "SMCHelper")
    private let smc: SMCClient?
    private let initError: String?
    
    override init() {
        do {
            smc = try SMCClient()
            initError = nil
            Self.logger.info("SMC client ready")
        } catch {
            smc = nil
            initError = error.localizedDescription
            Self.logger.error("SMC client init failed: \(error.localizedDescription, privacy: .public)")
        }
        
        super.init()
    }
    
    func readFans(withReply reply: @escaping ([FanSnapshot]?, String?) -> Void) {
        guard let smc else {
            reply(nil, initError ?? "SMC unavailable")
            return
        }
        
        do {
            let fans = try smc.readFans()
            reply(fans.map(FanSnapshot.init(fan:)), nil)
        } catch {
            Self.logger.error("readFans failed: \(error.localizedDescription, privacy: .public)")
            reply(nil, error.localizedDescription)
        }
    }
    
    func setManualRPM(fanID: Int, rpm: Double, withReply reply: @escaping (String?) -> Void) {
        guard let smc else {
            reply(initError ?? "SMC unavailable")
            return
        }
        
        do {
            Self.logger.info("setManualRPM fan=\(fanID, privacy: .public) rpm=\(rpm, privacy: .public)")
            try smc.setFanManualRPM(fanID: fanID, rpm: rpm)
            reply(nil)
        } catch {
            Self.logger.error("setManualRPM failed fan=\(fanID, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            reply(error.localizedDescription)
        }
    }
    
    func setAuto(fanID: Int, withReply reply: @escaping (String?) -> Void) {
        guard let smc else {
            reply(initError ?? "SMC unavailable")
            return
        }
        
        do {
            Self.logger.info("setAuto fan=\(fanID, privacy: .public)")
            try smc.setFanAuto(fanID: fanID)
            reply(nil)
        } catch {
            Self.logger.error("setAuto failed fan=\(fanID, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            reply(error.localizedDescription)
        }
    }
    
    func keepAliveManualOverride(withReply reply: @escaping (String?) -> Void) {
        guard let smc else {
            reply(initError ?? "SMC unavailable")
            return
        }
        
        do {
            try smc.keepAliveManualOverride()
            reply(nil)
        } catch {
            Self.logger.error("keepAlive failed: \(error.localizedDescription, privacy: .public)")
            reply(error.localizedDescription)
        }
    }
}

final class FanControlHelperDelegate: NSObject, NSXPCListenerDelegate {
    private static let logger = Logger(subsystem: "FanControl", category: "SMCHelper")
    private let service = FanControlHelperService()
    
    nonisolated func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = FanControlXPCInterface.make()
        newConnection.exportedObject = service
        newConnection.resume()
        Self.logger.info("Accepted helper connection")
        return true
    }
}
