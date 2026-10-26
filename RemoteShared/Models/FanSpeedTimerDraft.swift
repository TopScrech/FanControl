import Foundation

struct FanSpeedTimerDraft {
    var rpm = 2000.0
    var hours = 0
    var minutes = 30

    var duration: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60)
    }

    func isValid(minimumRPM: Double, maximumRPM: Double) -> Bool {
        rpm.isFinite && rpm >= minimumRPM && rpm <= maximumRPM &&
        (0...23).contains(hours) && (0...59).contains(minutes) && duration > 0
    }
}
