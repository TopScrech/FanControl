import Foundation

struct FanTimerRequest: Equatable {
    let rpm: Int
    let duration: TimeInterval
    let userFacingFanID: Int?
}
