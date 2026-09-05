import XCTest

@MainActor
final class ComponentRegistrationTests: XCTestCase {
    func testApprovalRetriesRegistrationAndFinishesAfterHandshake() async throws {
        let driver = FakeComponentRegistration()
        driver.state = .requiresApproval
        driver.approvalOnNextPause = true
        var phases = [ComponentInstallPhase]()
        try await ComponentRegistration().run(driver: driver, attempts: 3) { phases.append($0) }
        XCTAssertEqual(driver.registrationCount, 2)
        XCTAssertEqual(driver.settingsCount, 1)
        XCTAssertEqual(driver.handshakeCount, 1)
        XCTAssertEqual(phases, [.waitingForApproval, .connecting, .ready])
    }

    func testPermissionErrorBeforeApprovalStateRetriesAutomatically() async throws {
        let driver = FakeComponentRegistration()
        driver.pendingPermissionErrors = 1
        var phases = [ComponentInstallPhase]()
        try await ComponentRegistration().run(driver: driver, attempts: 3) { phases.append($0) }
        XCTAssertEqual(driver.registrationCount, 2)
        XCTAssertEqual(driver.settingsCount, 1)
        XCTAssertEqual(phases, [.waitingForApproval, .connecting, .ready])
    }

    func testRepeatedInstallPreservesEnabledService() async throws {
        let driver = FakeComponentRegistration()
        driver.state = .enabled
        let registration = ComponentRegistration()
        try await registration.run(driver: driver) { _ in }
        try await registration.run(driver: driver) { _ in }
        XCTAssertEqual(driver.registrationCount, 0)
        XCTAssertEqual(driver.handshakeCount, 2)
    }

    func testRestorationFailureNeverUnregisters() async {
        var unregistered = false
        do {
            try await ComponentRegistration.prepareReplacement(
                state: .enabled,
                restore: { throw NSError(domain: "TestRestoration", code: 1) },
                unregister: { unregistered = true }
            )
            XCTFail("An enabled helper requires confirmed restoration")
        } catch { XCTAssertEqual((error as NSError).domain, "TestRestoration") }
        XCTAssertFalse(unregistered)
    }

    func testConcurrentRegistrationIsRejected() async throws {
        let registration = ComponentRegistration()
        let driver = FakeComponentRegistration()
        driver.state = .requiresApproval
        driver.approvalOnNextPause = true
        var rejected = false
        driver.pauseAction = {
            do {
                try await registration.run(driver: driver) { _ in }
                XCTFail("Concurrent registration should not enter the lifecycle")
            } catch { rejected = true }
        }
        try await registration.run(driver: driver, attempts: 3) { _ in }
        XCTAssertTrue(rejected)
        XCTAssertEqual(driver.registrationCount, 2)
    }

    func testUnrelatedCodeOneIsNotApproval() {
        XCTAssertFalse(ComponentRegistration.isPendingApproval(NSError(domain: "OtherFailure", code: 1), state: .requiresApproval))
        XCTAssertTrue(ComponentRegistration.isPendingApproval(NSError(domain: "SMAppServiceErrorDomain", code: 1), state: .notRegistered))
        XCTAssertFalse(ComponentRegistration.isPendingApproval(NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM)), state: .notFound))
    }

    func testPendingApprovalHasBoundedRetries() async {
        let driver = FakeComponentRegistration()
        driver.state = .requiresApproval
        do {
            try await ComponentRegistration().run(driver: driver, attempts: 2) { _ in }
            XCTFail("Approval should time out")
        } catch { XCTAssertTrue(error.localizedDescription.contains("timed out")) }
        XCTAssertEqual(driver.registrationCount, 2)
        XCTAssertEqual(driver.settingsCount, 1)
        XCTAssertEqual(driver.handshakeCount, 0)
    }
}
