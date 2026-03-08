extension TemperatureSensorCategory {
    var sensorKey: String {
        "average.\(rawValue)"
    }
    
    func averageCelsius(in sensors: [TemperatureSensor]) -> Double? {
        let values = sensors
            .filter { contains(sensor: $0) }
            .map(\.celsius)
        
        guard !values.isEmpty else { return nil }
        
        return values.reduce(0, +) / Double(values.count)
    }
    
    func averageSensor(in sensors: [TemperatureSensor]) -> TemperatureSensor? {
        guard let averageCelsius = averageCelsius(in: sensors) else {
            return nil
        }
        
        return TemperatureSensor(
            key: sensorKey,
            celsius: averageCelsius,
            displayName: title
        )
    }
}
