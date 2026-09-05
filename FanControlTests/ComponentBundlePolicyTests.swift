import XCTest

final class ComponentBundlePolicyTests: XCTestCase {
    func testVersionAndBuildPreventDowngrade() throws {
        let installed = try ComponentRelease(version: "1.8", build: "0")
        XCTAssertLessThan(try ComponentRelease(version: "1.7", build: "99"), installed)
        XCTAssertLessThan(installed, try ComponentRelease(version: "1.8", build: "2"))
        XCTAssertLessThan(installed, try ComponentRelease(version: "1.10", build: "0"))
        XCTAssertEqual(installed, try ComponentRelease(version: "1.8", build: "0"))
        XCTAssertThrowsError(try ComponentRelease(version: "", build: "0"))
        XCTAssertThrowsError(try ComponentRelease(version: "1.8", build: "beta"))
    }

    func testInstallLockExcludesConcurrentInstallerAndReleases() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var first: ComponentInstallLock? = try ComponentInstallLock(directory: directory)
        try withExtendedLifetime(first) {
            XCTAssertThrowsError(try ComponentInstallLock(directory: directory))
        }
        first = nil
        XCTAssertNoThrow(try ComponentInstallLock(directory: directory))
    }
}
