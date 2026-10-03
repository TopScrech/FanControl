import CoreSMC
@testable import FanCLITestsSupport

final class TimerSMCService: SMCService {
    var fans = [
        Fan(id: 0, minRPM: 1000, maxRPM: 5000, currentRPM: 2000, targetRPM: 2000, mode: 1),
        Fan(id: 1, minRPM: 1000, maxRPM: 5000, currentRPM: 2000, targetRPM: 2000, mode: 1)
    ]
    var autoFanIDs = [Int]()
    var manualFanIDs = [Int]()
    var keepAliveCount = 0
    var failsKeepAlive = false
    var failsReadFans = false
    var failsFirstReset = false

    func readFans() async throws -> [Fan] {
        if failsReadFans { throw FanCLIError.failure("Could not read helper fan snapshots") }
        return fans
    }

    func setFanManualRPM(fanID: Int, rpm: Double) async throws {
        manualFanIDs.append(fanID)
    }

    func setFanAuto(fanID: Int) async throws {
        autoFanIDs.append(fanID)
        if failsFirstReset && fanID == 0 { throw FanCLIError.failure("Reset failed") }
    }

    func keepAliveManualOverride() async throws {
        keepAliveCount += 1
        if failsKeepAlive { throw FanCLIError.failure("Keep-alive failed") }
    }
}
