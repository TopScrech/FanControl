import ScrechKit

struct TemperatureSensorsSheetView: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    @AppStorage("showsTemperatureSensorIcons") private var showsTemperatureSensorIcons = false
    
    let sensors: [TemperatureSensor]
    
    var body: some View {
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
            
            ScrollView {
                TemperatureSensorsCard(
                    sensors: sensors,
                    temperatureUnit: temperatureUnit,
                    showsTemperatureTenths: temperaturePrecision.showsTenths,
                    showsIcons: showsTemperatureSensorIcons
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
        }
        .padding()
        .frame(minWidth: 320, idealWidth: 320, maxWidth: 320, minHeight: 420, alignment: .topLeading)
        .background(ContentViewBackground())
    }
    
    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }
    
    private var temperaturePrecision: TemperaturePrecision {
        TemperaturePrecision(rawValue: temperaturePrecisionRawValue) ?? .whole
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
