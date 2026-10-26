import Foundation

struct RemoteFanState: Codable, Hashable, Identifiable, Sendable {
    let id: Int
    let minRPM: Double
    let maxRPM: Double
    let currentRPM: Double
    let targetRPM: Double
    let mode: UInt8
    let activeAction: RemoteFanAction?
    var supportsTimers: Bool? = nil
    var timerEndDate: Date? = nil
    var timerRPM: Double? = nil
}
