import Foundation

struct RemoteFanCommand: Identifiable, Hashable, Sendable {
    static let allFansID = -1
    static let validityInterval: TimeInterval = 30

    let id: String
    let deviceID: String
    let fanID: Int
    let action: RemoteFanAction
    let createdAt: Date
    let status: Status
    let errorMessage: String?

    var isExpired: Bool {
        Date().timeIntervalSince(createdAt) > Self.validityInterval
    }

    enum Status: String, Sendable {
        case pending, completed, failed
    }
}
