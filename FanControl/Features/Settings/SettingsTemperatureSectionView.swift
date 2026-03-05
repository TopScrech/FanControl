import ScrechKit

struct SettingsTemperatureSectionView: View {
    @Binding var temperatureUnitRawValue: String
    @Binding var temperaturePrecisionRawValue: String

    var body: some View {
        Section("Temperature") {
            Picker("Measurement unit", selection: $temperatureUnitRawValue) {
                ForEach(TemperatureUnit.allCases) {
                    Text($0.pickerTitle)
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
