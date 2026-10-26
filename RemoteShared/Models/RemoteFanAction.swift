enum RemoteFanAction: String, Codable, CaseIterable, Sendable {
    case automatic, minimum, maximum, startTimer, cancelTimer
}
