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
    
    var pickerTitle: String {
        switch self {
        case .celsius: "\(String(localized: "Celsius")) (°C)"
        case .fahrenheit: "\(String(localized: "Fahrenheit")) (°F)"
        case .kelvin: "\(String(localized: "Kelvin")) (K)"
        }
    }
}
