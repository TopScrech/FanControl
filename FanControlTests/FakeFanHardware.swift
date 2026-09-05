import CoreSMC
import Foundation

@MainActor
final class FakeFanHardware: ComponentFanHardware {
    var manualWrites = [Int]()
    var automaticWrites = [Int]()
    var shouldFailManual = false
    var shouldFailAutomatic = false
    var heartbeats = 0

    func readFans() throws -> [Fan] {
        [Fan(id: 0, minRPM: 1000, maxRPM: 5000, currentRPM: 1500, targetRPM: 1500, mode: 0)]
    }
    func setFanManualRPM(fanID: Int, rpm: Double) throws {
        manualWrites.append(fanID)
        if shouldFailManual { throw NSError(domain: "MockSMC", code: 1) }
    }
    func setFanAuto(fanID: Int) throws {
        if shouldFailAutomatic { throw NSError(domain: "MockSMC", code: 2) }
        automaticWrites.append(fanID)
    }
    func keepAliveManualOverride() throws { heartbeats += 1 }
}
