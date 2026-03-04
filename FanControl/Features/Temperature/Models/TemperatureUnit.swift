import SwiftUI

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius, fahrenheit, kelvin
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .celsius: "Celsius"
        case .fahrenheit: "Fahrenheit"
        case .kelvin: "Kelvin"
        }
    }
}
