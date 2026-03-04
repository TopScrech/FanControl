import OSLog
import CoreSMC

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
            Self.logger.error("SMC client init failed: \(error.localizedDescription)")
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
            Self.logger.error("readFans failed: \(error.localizedDescription)")
            reply(nil, error.localizedDescription)
        }
    }
    
    func readTemperatureSensors(withReply reply: @escaping ([TemperatureSensorSnapshot]?, String?) -> Void) {
        guard let smc else {
            reply(nil, initError ?? "SMC unavailable")
            return
        }
        
        do {
            let sensors = try smc.readTemperatureSensors()
            reply(sensors.map(TemperatureSensorSnapshot.init(sensor:)), nil)
        } catch {
            Self.logger.error("readTemperatureSensors failed: \(error.localizedDescription)")
            reply(nil, error.localizedDescription)
        }
    }
    
    func setManualRPM(fanID: Int, rpm: Double, withReply reply: @escaping (String?) -> Void) {
        guard let smc else {
            reply(initError ?? "SMC unavailable")
            return
        }
        
        do {
            Self.logger.info("setManualRPM fan=\(fanID) rpm=\(rpm)")
            try smc.setFanManualRPM(fanID: fanID, rpm: rpm)
            reply(nil)
        } catch {
            Self.logger.error("setManualRPM failed fan=\(fanID) error=\(error.localizedDescription)")
            reply(error.localizedDescription)
        }
    }
    
    func setAuto(fanID: Int, withReply reply: @escaping (String?) -> Void) {
        guard let smc else {
            reply(initError ?? "SMC unavailable")
            return
        }
        
        do {
            Self.logger.info("setAuto fan=\(fanID)")
            try smc.setFanAuto(fanID: fanID)
            reply(nil)
        } catch {
            Self.logger.error("setAuto failed fan=\(fanID) error=\(error.localizedDescription)")
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
            Self.logger.error("keepAlive failed: \(error.localizedDescription)")
            reply(error.localizedDescription)
        }
    }
}
