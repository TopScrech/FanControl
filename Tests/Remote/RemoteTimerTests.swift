import Foundation
import Testing
@testable import RemoteTimersSupport

struct RemoteTimerTests {
    @Test func olderHostStateRemainsReadable() throws {
        let data = Data(#"{"id":0,"minRPM":1200,"maxRPM":6000,"currentRPM":2000,"targetRPM":2000,"mode":1,"activeAction":"minimum"}"#.utf8)
        let fan = try JSONDecoder().decode(RemoteFanState.self, from: data)
        #expect(fan.supportsTimers == nil)
        #expect(fan.timerEndDate == nil)
        #expect(fan.timerRPM == nil)
    }

    @Test func hostTimerStateRoundTrips() throws {
        let fan = RemoteFanState(
            id: 0, minRPM: 1200, maxRPM: 6000, currentRPM: 2500,
            targetRPM: 2500, mode: 1, activeAction: nil,
            supportsTimers: true, timerEndDate: Date(timeIntervalSince1970: 1800000000), timerRPM: 2500
        )
        let decoded = try JSONDecoder().decode(RemoteFanState.self, from: JSONEncoder().encode(fan))
        #expect(decoded == fan)
    }

    @Test func timerDraftRejectsInvalidDurationsAndSpeeds() {
        for draft in [
            FanSpeedTimerDraft(rpm: 2000, hours: 0, minutes: 0),
            FanSpeedTimerDraft(rpm: 2000, hours: 24, minutes: 0),
            FanSpeedTimerDraft(rpm: 2000, hours: 0, minutes: 60),
            FanSpeedTimerDraft(rpm: 2000, hours: -1, minutes: 30),
            FanSpeedTimerDraft(rpm: .nan),
            FanSpeedTimerDraft(rpm: .infinity),
            FanSpeedTimerDraft(rpm: 1199),
            FanSpeedTimerDraft(rpm: 6001)
        ] {
            #expect(!draft.isValid(minimumRPM: 1200, maximumRPM: 6000))
        }
    }

    @Test func timerDraftAcceptsDurationBoundaries() {
        let shortest = FanSpeedTimerDraft(rpm: 1200, hours: 0, minutes: 1)
        let longest = FanSpeedTimerDraft(rpm: 6000, hours: 23, minutes: 59)
        #expect(shortest.isValid(minimumRPM: 1200, maximumRPM: 6000))
        #expect(longest.isValid(minimumRPM: 1200, maximumRPM: 6000))
        #expect(shortest.duration == 60)
        #expect(longest.duration == 86340)
    }
}
