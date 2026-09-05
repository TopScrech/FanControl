#if !APP_STORE
import CoreSMC
#endif

protocol SMCService {
    func readFans() async throws -> [Fan]
    func setFanManualRPM(fanID: Int, rpm: Double) async throws
    func setFanAuto(fanID: Int) async throws
    func keepAliveManualOverride() async throws
}
