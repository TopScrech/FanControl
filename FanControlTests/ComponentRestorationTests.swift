import XCTest

@MainActor
final class ComponentRestorationTests: XCTestCase {
    func testTransientInvalidConnectionRetriesBeforeUnregistering() async throws {
        var attempts = 0
        var unregistered = false
        try await ComponentRegistration.prepareReplacement(
            state: .enabled,
            restore: {
                try await ComponentRestoration.confirm(restore: {
                    attempts += 1
                    if attempts == 1 { throw NSError(domain: NSCocoaErrorDomain, code: NSXPCConnectionInvalid) }
                }, pause: {})
            },
            unregister: { unregistered = true }
        )
        XCTAssertEqual(attempts, 2)
        XCTAssertTrue(unregistered)
    }

    func testUnavailableHelperExhaustsRetriesWithoutUnregistering() async {
        var attempts = 0
        var unregistered = false
        do {
            try await ComponentRegistration.prepareReplacement(
                state: .enabled,
                restore: {
                    try await ComponentRestoration.confirm(restore: {
                        attempts += 1
                        throw NSError(domain: NSCocoaErrorDomain, code: NSXPCConnectionInvalid)
                    }, pause: {})
                },
                unregister: { unregistered = true }
            )
            XCTFail("Unreachable enabled helpers must still block replacement")
        } catch { XCTAssertEqual((error as NSError).code, NSXPCConnectionInvalid) }
        XCTAssertEqual(attempts, 4)
        XCTAssertFalse(unregistered)
    }

    func testHardwareFailureDoesNotRetry() async {
        var attempts = 0
        do {
            try await ComponentRestoration.confirm(restore: {
                attempts += 1
                throw NSError(domain: "FanControlComponent", code: 1)
            }, pause: {})
            XCTFail("Hardware restoration failure must propagate")
        } catch { XCTAssertEqual((error as NSError).domain, "FanControlComponent") }
        XCTAssertEqual(attempts, 1)
    }

    func testCancellationDuringRetryStopsFurtherAttempts() async {
        var attempts = 0
        do {
            try await ComponentRestoration.confirm(restore: {
                attempts += 1
                throw NSError(domain: NSCocoaErrorDomain, code: NSXPCConnectionInterrupted)
            }, pause: { throw CancellationError() })
            XCTFail("Cancellation must propagate")
        } catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertEqual(attempts, 1)
    }
}
