import SwiftUI

struct SettingsTemperatureSection: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    
    var body: some View {
        Section("Temperature") {
            Picker("Measurement unit", selection: $temperatureUnitRawValue) {
                ForEach(TemperatureUnit.allCases) {
                    (Text($0.title) + Text(" (\($0.symbol))"))
                        .tag($0.rawValue)
                }
            }
            .pickerStyle(.menu)
            
            Picker("Precision", selection: $temperaturePrecisionRawValue) {
                ForEach(TemperaturePrecision.allCases) {
                    Text($0.title)
                        .tag($0.rawValue)
                }
            }
            .pickerStyle(.menu)
        }
    }
}
