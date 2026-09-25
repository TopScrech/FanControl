import SwiftUI

final class FanSpinClock {
    private static let degreesPerSecondPerRPM = 0.11
    private static let maxDegreesPerSecond = 480.0
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
