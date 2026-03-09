import Foundation

extension Double {
    func formattedTemperature(in unit: TemperatureUnit, showsTenths: Bool) -> String {
        let fractionLength = showsTenths ? 1 : 0
        
        return switch unit {
        case .celsius:
            "\(formatted(.number.precision(.fractionLength(fractionLength)))) °C"
            
        case .fahrenheit:
            "\((self * 9 / 5 + 32).formatted(.number.precision(.fractionLength(fractionLength)))) °F"
            
        case .kelvin:
            "\((self + 273.15).formatted(.number.precision(.fractionLength(fractionLength)))) K"
        }
    }
}
