struct TemperatureSensor: Identifiable, Equatable, Sendable {
    let key: String
    let celsius: Double
    let displayName: String
    
    var id: String {
        "\(displayName):\(key)"
    }
}
