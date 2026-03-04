import Foundation
import CoreSMC

enum TemperatureSensorCategory: String, CaseIterable, Identifiable {
    case battery, cpu, gpu
    
    var id: String {
        rawValue
    }
    
    var title: String {
        rawValue.uppercased()
    }
    
    func contains(sensor: TemperatureSensor) -> Bool {
        let normalizedName = sensor.displayName.lowercased()
        
        switch self {
        case .battery:
            return normalizedName.contains("battery")
            
        case .cpu:
            return normalizedName.contains("cpu")
            
        case .gpu:
            return normalizedName.contains("gpu")
        }
    }
}
