extension TemperatureSensorCategory {
    var systemImage: String {
        switch self {
        case .cpu: "cpu"
        case .gpu: "memorychip"
        case .battery: "battery.100"
        }
    }
}
