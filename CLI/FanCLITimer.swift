import Foundation
import CoreSMC

enum FanCLITimer {
    static func run(
        _ request: FanTimerRequest,
        targetFans: [Fan],
        targetRPMs: [Int: Double],
        smc: SMCService,
        readFans: () async throws -> [Fan],
        start: () async throws -> Void
    ) async throws {
        guard fan_timer_signal_start() == 0 else {
            throw FanCLIError.failure("Could not install timer interruption handlers")
        }
        defer { fan_timer_signal_stop() }

        var timerError: Error?
        do {
            try await start()
            let endDate = Date.now.addingTimeInterval(request.duration)
            print("Timer running until \(endDate.formatted(date: .omitted, time: .standard)) — press Ctrl-C to cancel and return to auto")
            var nextRefresh = Date.now

            while Date.now < endDate {
                try Self.checkInterruption()
                if Date.now >= nextRefresh {
                    try await smc.keepAliveManualOverride()
                    let currentFans = try await readFans()

                    for fan in currentFans {
                        guard let rpm = targetRPMs[fan.id] else { continue }
                        try Self.checkInterruption()
                        if fan.mode == 0 || fan.mode == 3 || abs(fan.targetRPM - rpm) > 1 {
                            try await smc.setFanManualRPM(fanID: fan.id, rpm: rpm)
                        }
                    }
                    nextRefresh = .now.addingTimeInterval(1)
                }

                try await Task.sleep(for: .seconds(min(0.25, max(0, endDate.timeIntervalSinceNow))))
            }
            try Self.checkInterruption()
        } catch {
            timerError = error
        }

        var resetFailures = [String]()
        for fan in targetFans {
            do {
                try await smc.setFanAuto(fanID: fan.id)
            } catch {
                resetFailures.append("\(fan.cliDisplayName): \(error.localizedDescription)")
            }
        }

        if !resetFailures.isEmpty {
            let reason = timerError.map { "\($0.localizedDescription)\n" } ?? ""
            throw FanCLIError.failure("\(reason)Could not return fans to auto: \(resetFailures.joined(separator: "; "))")
        }

        if let error = timerError as? FanCLIError, error.exitCode >= 128 {
            throw FanCLIError.failure("\(error.message), returned fans to auto", exitCode: error.exitCode)
        }
        if let timerError { throw timerError }
    }

    static func checkInterruption() throws {
        let signal = fan_timer_signal_received()
        guard signal == 0 else {
            throw FanCLIError.failure("Timer cancelled", exitCode: 128 + signal)
        }
        try Task.checkCancellation()
    }
}
