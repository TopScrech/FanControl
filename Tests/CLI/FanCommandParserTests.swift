import Testing
@testable import FanCLITestsSupport

struct FanCommandParserTests {
    @Test(arguments: [
        (["timer", "4k", "30m"], FanTimerRequest(rpm: 4000, duration: 1800, userFacingFanID: nil)),
        (["-id", "2", "timer", "1.6k", "1h30m"], FanTimerRequest(rpm: 1600, duration: 5400, userFacingFanID: 2)),
        (["--id", "1", "timer", "2000", "60s"], FanTimerRequest(rpm: 2000, duration: 60, userFacingFanID: 1)),
        (["timer", "2000", "23h59m"], FanTimerRequest(rpm: 2000, duration: 86_340, userFacingFanID: nil))
    ])
    func parsedTimers(arguments: [String], expected: FanTimerRequest) throws {
        guard case .timer(let request) = try FanCommandParser.parse(arguments: arguments) else {
            Issue.record("Expected a timer command")
            return
        }
        #expect(request == expected)
    }

    @Test(arguments: [
        ["timer"], ["timer", "4k"], ["timer", "4k", "30m", "extra"],
        ["timer", "auto", "30m"], ["timer", "0", "30m"],
        ["timer", "4k", "0s"], ["timer", "4k", "24h"],
        ["timer", "4k", "30"], ["timer", "4k", "-1m"],
        ["timer", "4k", "1.5h"], ["timer", "4k", "1m1h"],
        ["timer", "4k", "1h1h"], ["timer", "4k", "1h30"],
        ["timer", "4k", "999999999999999999999h"],
        ["-id", "0", "timer", "4k", "30m"], ["-id", "1", "timer", "4k"]
    ])
    func rejectedTimers(arguments: [String]) {
        #expect(throws: FanCLIError.self) {
            try FanCommandParser.parse(arguments: arguments)
        }
    }

    @Test func existingCommands() throws {
        guard case .setFanRPM(2, 1600) = try FanCommandParser.parse(arguments: ["-id", "2", "1.6k"]) else {
            Issue.record("Expected the existing fan RPM command")
            return
        }
        guard case .autoAll = try FanCommandParser.parse(arguments: ["auto"]) else {
            Issue.record("Expected the existing Auto command")
            return
        }
        #expect(throws: FanCLIError.self) {
            try FanCommandParser.parse(arguments: ["-id", "2", "auto", "extra"])
        }
    }
}
