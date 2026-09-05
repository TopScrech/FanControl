import XCTest

final class XPCReplyTests: XCTestCase {
    func testCancellationBeforeContinuationInstallation() async {
        let reply = XPCReply<Int>()
        reply.finish(.failure(CancellationError()))
        do {
            let _ = try await withCheckedThrowingContinuation { reply.install($0) }
            XCTFail("Cancellation must survive late continuation installation")
        } catch { XCTAssertTrue(error is CancellationError) }
    }

    func testRacingRepliesResumeExactlyOnce() async throws {
        let reply = XPCReply<Int>()
        let value: Int = try await withCheckedThrowingContinuation { continuation in
            reply.install(continuation)
            for number in 0..<100 {
                Task.detached { reply.finish(.success(number)) }
            }
        }
        XCTAssertTrue((0..<100).contains(value))
        reply.finish(.failure(CancellationError()))
    }
}
