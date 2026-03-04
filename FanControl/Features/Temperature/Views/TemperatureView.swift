import ScrechKit
import CoreSMC

struct TemperatureView: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    
    let sensors: [TemperatureSensor]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text("Temperature sensors")
                        .headline()
                    
                    Spacer(minLength: 0)
#if DEBUG
                    Button("Copy", action: copyAllSensors)
                        .disabled(sensors.isEmpty)
#endif
                }
                
                TemperatureAveragesCardView(rows: averageRows)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TemperatureSensorsCardView(
                    sensors: otherSensors,
                    temperatureUnit: temperatureUnit,
                    showsTemperatureTenths: temperaturePrecision.showsTenths
                )
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }
    
    private var temperaturePrecision: TemperaturePrecision {
        TemperaturePrecision(rawValue: temperaturePrecisionRawValue) ?? .whole
    }
    
    private var averageRows: [TemperatureAverageRow] {
        TemperatureSensorCategory.allCases.map { category in
            let values = sensors
                .filter { category.contains(sensor: $0) }
                .map(\.celsius)
            
            let averageText: String
            
            if values.isEmpty {
                averageText = "--"
            } else {
                let average = values.reduce(0, +) / Double(values.count)
                averageText = average.formattedTemperature(in: temperatureUnit, showsTenths: temperaturePrecision.showsTenths)
            }
            
            return TemperatureAverageRow(
                id: category.rawValue,
                title: category.title,
                value: averageText
            )
        }
    }
    
    private var otherSensors: [TemperatureSensor] {
        sensors.filter { sensor in
            !TemperatureSensorCategory.allCases.contains {
                $0.contains(sensor: sensor)
            }
        }
    }
#if DEBUG
    private func copyAllSensors() {
        let text = sensors
            .map {
                "\($0.key) (\($0.displayName)): \($0.celsius.formattedTemperature(in: temperatureUnit, showsTenths: temperaturePrecision.showsTenths))"
            }
            .joined(separator: "\n")
        
        guard !text.isEmpty else { return }
#if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
#endif
    }
#endif
}
