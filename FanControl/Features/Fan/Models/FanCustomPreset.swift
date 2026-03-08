struct FanCustomPreset: Codable, Equatable, Sendable, Identifiable {
    static let temperatureBounds = 10...110
    
    let fanID: Int
    var sensorKey: String
    var sensorDisplayName: String
    var minimumTemperature: Int
    var maximumTemperature: Int
    var isEnabled: Bool
    
    var id: Int {
        fanID
    }
}
