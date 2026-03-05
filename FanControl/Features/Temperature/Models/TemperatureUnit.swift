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
    
    var symbol: String {
        switch self {
        case .celsius: "°C"
        case .fahrenheit: "°F"
        case .kelvin: "K"
        }
    }
}
