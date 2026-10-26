import Foundation

enum RemoteControlHostError: LocalizedError {
    case fanUnavailable, helperUnavailable, licenseRequired, timerAlreadyRunning, invalidTimer, timerInterrupted
    
    var errorDescription: String? {
        switch self {
        case .licenseRequired: "Fan timers require an active license"
        case .timerAlreadyRunning: "A fan timer is already running on this Mac"
        case .invalidTimer: "Choose a valid fan speed and a duration between 1 minute and 23 hours 59 minutes"
        case .timerInterrupted: "The timer could not be updated on the Mac"
        case .fanUnavailable: "The selected fan is no longer available"
        case .helperUnavailable: "The privileged helper is not available"
        }
    }
}
