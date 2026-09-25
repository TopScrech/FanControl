import SwiftUI

// Accumulates the glyph angle so speed changes don't make the blades jump
final class FanSpinClock {
    // Scaled down from real RPM to stay readable and avoid strobing
    private static let degreesPerSecondPerRPM = 0.11

    private var degrees = 0.0
    private var lastDate: Date?

    func angle(at date: Date, rpm: Double) -> Angle {
        if let lastDate {
            let elapsed = min(max(date.timeIntervalSince(lastDate), 0), 0.1)
            degrees = (degrees + rpm * Self.degreesPerSecondPerRPM * elapsed).truncatingRemainder(dividingBy: 360)
        }

        lastDate = date
        return .degrees(degrees)
    }
}
