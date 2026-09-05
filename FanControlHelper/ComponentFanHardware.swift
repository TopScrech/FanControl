import CoreSMC

@MainActor
protocol ComponentFanHardware {
    func readFans() throws -> [Fan]
    func setFanManualRPM(fanID: Int, rpm: Double) throws
    func setFanAuto(fanID: Int) throws
    func keepAliveManualOverride() throws
}
