import XCTest

@MainActor
final class FanControlEngineTests: XCTestCase {
    func testRejectsInvalidCommandsWithoutHardwareWrites() throws {
        let hardware = FakeFanHardware()
        let engine = FanControlEngine(controller: hardware)
        let owner = UUID()
        for rpm in [Double.nan, .infinity, -.infinity, -1, 999, 5001] {
            XCTAssertThrowsError(try engine.setManualRPM(owner: owner, fanID: 0, rpm: rpm))
        }
        XCTAssertThrowsError(try engine.setManualRPM(owner: owner, fanID: 99, rpm: 2000))
        XCTAssertThrowsError(try engine.setAuto(owner: owner, fanID: 99))
        XCTAssertTrue(hardware.manualWrites.isEmpty)
        XCTAssertTrue(hardware.automaticWrites.isEmpty)
    }

    func testOnlyControllingConnectionCanWriteOrReleaseLease() throws {
        let hardware = FakeFanHardware()
        let engine = FanControlEngine(controller: hardware)
        let owner = UUID()
        try engine.setManualRPM(owner: owner, fanID: 0, rpm: 2000)
        XCTAssertThrowsError(try engine.setManualRPM(owner: UUID(), fanID: 0, rpm: 2000))
        XCTAssertThrowsError(try engine.setAuto(owner: UUID(), fanID: 0))
        engine.restore(owner: UUID())
        XCTAssertTrue(hardware.automaticWrites.isEmpty)
        engine.restore(owner: owner)
        XCTAssertEqual(hardware.automaticWrites, [0])
        try engine.setManualRPM(owner: UUID(), fanID: 0, rpm: 2500)
    }

    func testExpiredHeartbeatRestoresSystemControl() throws {
        let hardware = FakeFanHardware()
        let engine = FanControlEngine(controller: hardware)
        try engine.setManualRPM(owner: UUID(), fanID: 0, rpm: 2000)
        engine.checkLease(now: .now.advanced(by: .seconds(11)))
        XCTAssertEqual(hardware.automaticWrites, [0])
    }

    func testLiveHeartbeatDoesNotResetFans() throws {
        let hardware = FakeFanHardware()
        let engine = FanControlEngine(controller: hardware)
        let owner = UUID()
        try engine.setManualRPM(owner: owner, fanID: 0, rpm: 2000)
        try engine.keepAlive(owner: owner)
        engine.checkLease()
        XCTAssertEqual(hardware.heartbeats, 1)
        XCTAssertTrue(hardware.automaticWrites.isEmpty)
    }

    func testPartialWriteFailureRestoresMode() {
        let hardware = FakeFanHardware()
        hardware.shouldFailManual = true
        let engine = FanControlEngine(controller: hardware)
        XCTAssertThrowsError(try engine.setManualRPM(owner: UUID(), fanID: 0, rpm: 2000))
        XCTAssertEqual(hardware.automaticWrites, [0])
    }

    func testUpdateStopsFurtherManualWrites() throws {
        let hardware = FakeFanHardware()
        let engine = FanControlEngine(controller: hardware)
        let owner = UUID()
        try engine.setManualRPM(owner: owner, fanID: 0, rpm: 2000)
        try engine.prepareForUpdate()
        XCTAssertEqual(hardware.automaticWrites, [0])
        XCTAssertThrowsError(try engine.setManualRPM(owner: owner, fanID: 0, rpm: 2000))
    }

    func testFailedRestorationBlocksUpdateAndCanBeRetried() throws {
        let hardware = FakeFanHardware()
        let engine = FanControlEngine(controller: hardware)
        try engine.setManualRPM(owner: UUID(), fanID: 0, rpm: 2000)
        hardware.shouldFailAutomatic = true
        XCTAssertThrowsError(try engine.prepareForUpdate())
        hardware.shouldFailAutomatic = false
        try engine.prepareForUpdate()
        XCTAssertEqual(hardware.automaticWrites, [0])
    }
}
