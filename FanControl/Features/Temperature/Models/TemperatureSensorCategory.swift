import Foundation

enum TemperatureSensorCategory: String, CaseIterable, Identifiable {
    case cpu, gpu, battery
    
    static func averageCases(isMacBook: Bool) -> [Self] {
        isMacBook ? allCases : allCases.filter { $0 != .battery }
    }
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .cpu: String(localized: "Avg. CPU")
        case .gpu: String(localized: "Avg. GPU")
        case .battery: String(localized: "Avg. Battery")
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
