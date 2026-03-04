import CoreSMC

final class LocalSMCService: SMCService {
    private let smc: SMCClient
    
    init() throws {
        smc = try SMCClient()
    }
    
    func readFans() async throws -> [Fan] {
        try smc.readFans()
    }
    
    func readTemperatureSensors() async throws -> [TemperatureSensor] {
        try smc.readTemperatureSensors()
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
