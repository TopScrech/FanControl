import XCTest

final class FanSnapshotTests: XCTestCase {
    func testSecureArchiveUsesStableCrossProcessClassName() throws {
        // The app and daemon have different Swift module names
        XCTAssertEqual(NSStringFromClass(FanSnapshot.self), "FanSnapshot")
        let original = FanSnapshot(id: 2, minRPM: 1000, maxRPM: 5000, currentRPM: 2200, targetRPM: 2500, mode: 1)
        let data = try NSKeyedArchiver.archivedData(withRootObject: original, requiringSecureCoding: true)
        let decoded = try XCTUnwrap(NSKeyedUnarchiver.unarchivedObject(ofClass: FanSnapshot.self, from: data))
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.minRPM, original.minRPM)
        XCTAssertEqual(decoded.maxRPM, original.maxRPM)
        XCTAssertEqual(decoded.currentRPM, original.currentRPM)
        XCTAssertEqual(decoded.targetRPM, original.targetRPM)
        XCTAssertEqual(decoded.mode, original.mode)
    }
}
