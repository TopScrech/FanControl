enum TemperatureSensorCategory: String, CaseIterable, Identifiable {
    case cpu, gpu, battery
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .cpu: "Avg. CPU"
        case .gpu: "Avg. GPU"
        case .battery: "Avg. Battery"
        }
    }
    
    func contains(sensor: TemperatureSensor) -> Bool {
        let normalizedName = sensor.displayName.lowercased()
        
        switch self {
        case .battery: return normalizedName.contains("battery")
        case .cpu: return normalizedName.contains("cpu")
        case .gpu: return normalizedName.contains("gpu")
        }
    }
}
