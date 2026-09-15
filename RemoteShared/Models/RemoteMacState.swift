import Foundation

struct RemoteMacState: Identifiable, Hashable, Sendable {
    static let onlineInterval: TimeInterval = 45

    let id: String
    let name: String
    let updatedAt: Date
    let fans: [RemoteFanState]

    var isOnline: Bool {
        Date().timeIntervalSince(updatedAt) < Self.onlineInterval
    }
}
