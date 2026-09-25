import SwiftUI

// Accumulates the glyph angle so speed changes don't make the blades jump
final class FanSpinClock {
    // Scaled down from real RPM to stay readable
    private static let degreesPerSecondPerRPM = 0.11
    
    // Above this the blades start to strobe at common refresh rates
    private static let maxDegreesPerSecond = 480.0
    
    // Mimics fan spool-up so RPM readings don't change the speed abruptly
    private static let spoolTimeConstant = 1.2
    
    private var degrees = 0.0
    private var displayedRPM: Double?
    private var lastDate: Date?
    
    func angle(at date: Date, rpm: Double) -> Angle {
        let elapsed = lastDate.map { min(max(date.timeIntervalSince($0), 0), 0.1) } ?? 0
        lastDate = date
        
        let currentRPM = displayedRPM ?? rpm
        let nextRPM = currentRPM + (rpm - currentRPM) * (1 - exp(-elapsed / Self.spoolTimeConstant))
        displayedRPM = nextRPM
        
        let speed = min(nextRPM * Self.degreesPerSecondPerRPM, Self.maxDegreesPerSecond)
        degrees = (degrees + speed * elapsed).truncatingRemainder(dividingBy: 360)
        
        return .degrees(degrees)
    }
}
