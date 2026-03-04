import CoreSMC

protocol SMCService {
    func readFans() async throws -> [Fan]
    func readTemperatureSensors() async throws -> [TemperatureSensor]
    func setFanManualRPM(fanID: Int, rpm: Double) async throws
    func setFanAuto(fanID: Int) async throws
    func keepAliveManualOverride() async throws
}
