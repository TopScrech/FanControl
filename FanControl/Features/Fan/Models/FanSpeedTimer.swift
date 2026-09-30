import Foundation

struct FanSpeedTimer: Identifiable, Equatable {
    let id = UUID()
    let name: String
    var targetRPMs: [Int: Double]
    let startDate = Date.now
    var endDate: Date

    var rpmRange: ClosedRange<Double>? {
        guard let minimum = targetRPMs.values.min(), let maximum = targetRPMs.values.max() else { return nil }
        return minimum...maximum
    }

    func hasEnded(at date: Date = .now) -> Bool {
        date >= endDate
    }

    func remainingFraction(at date: Date = .now) -> Double {
        let total = endDate.timeIntervalSince(startDate)
        guard total > 0 else { return 0 }
        return min(max(endDate.timeIntervalSince(date) / total, 0), 1)
    }
}
