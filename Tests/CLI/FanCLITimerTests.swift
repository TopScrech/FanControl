import Foundation
import Testing
@testable import FanCLITestsSupport

@Suite(.serialized)
struct FanCLITimerTests {
    private let request = FanTimerRequest(rpm: 2000, duration: 0.01, userFacingFanID: nil)

    @Test func expiryReturnedAllTargetsToAuto() async throws {
        let smc = TimerSMCService()
        try await FanCLITimer.run(request, targetFans: smc.fans, targetRPMs: [0: 2000, 1: 2000], smc: smc, readFans: smc.readFans) {}
        #expect(smc.autoFanIDs == [0, 1])
        #expect(smc.keepAliveCount > 0)
    }

    @Test func scopedTimerLeftOtherFansAlone() async throws {
        let smc = TimerSMCService()
        try await FanCLITimer.run(request, targetFans: [smc.fans[1]], targetRPMs: [1: 3000], smc: smc, readFans: smc.readFans) {}
        #expect(smc.autoFanIDs == [1])
        #expect(smc.manualFanIDs == [1])
    }

    @Test func timerUsedCLIReaderWhenHelperSnapshotsFailed() async throws {
        let smc = TimerSMCService()
        smc.failsReadFans = true
        try await FanCLITimer.run(
            request,
            targetFans: smc.fans,
            targetRPMs: [0: 3000, 1: 3000],
            smc: smc,
            readFans: { smc.fans }
        ) {}
        #expect(smc.manualFanIDs == [0, 1])
        #expect(smc.autoFanIDs == [0, 1])
        #expect(smc.keepAliveCount > 0)
    }

    @Test func startFailureReturnedAllTargetsToAuto() async {
        let smc = TimerSMCService()
        await #expect(throws: FanCLIError.self) {
            try await FanCLITimer.run(request, targetFans: smc.fans, targetRPMs: [0: 2000, 1: 2000], smc: smc, readFans: smc.readFans) {
                throw FanCLIError.failure("Start failed")
            }
        }
        #expect(smc.autoFanIDs == [0, 1])
    }

    @Test func keepAliveFailureReturnedAllTargetsToAuto() async {
        let smc = TimerSMCService()
        smc.failsKeepAlive = true
        await #expect(throws: FanCLIError.self) {
            try await FanCLITimer.run(request, targetFans: smc.fans, targetRPMs: [0: 2000, 1: 2000], smc: smc, readFans: smc.readFans) {}
        }
        #expect(smc.autoFanIDs == [0, 1])
    }

    @Test func resetFailureStillAttemptedEveryTarget() async {
        let smc = TimerSMCService()
        smc.failsFirstReset = true
        await #expect(throws: FanCLIError.self) {
            try await FanCLITimer.run(request, targetFans: smc.fans, targetRPMs: [0: 2000, 1: 2000], smc: smc, readFans: smc.readFans) {}
        }
        #expect(smc.autoFanIDs == [0, 1])
    }

    @Test(arguments: [SIGINT, SIGTERM, SIGHUP])
    func interruptionReturnedAllTargetsToAuto(signal: Int32) async throws {
        let smc = TimerSMCService()
        do {
            try await FanCLITimer.run(request, targetFans: smc.fans, targetRPMs: [0: 2000, 1: 2000], smc: smc, readFans: smc.readFans) {
                raise(signal)
            }
            Issue.record("Expected an interruption error")
        } catch let error as FanCLIError {
            #expect(error.exitCode == 128 + signal)
            #expect(error.message == "Timer cancelled, returned fans to auto")
        }
        #expect(smc.autoFanIDs == [0, 1])
    }
}
