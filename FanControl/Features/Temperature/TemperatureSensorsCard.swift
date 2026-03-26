import ScrechKit

struct TemperatureSensorsCard: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    
    let sensors: [TemperatureSensor]
    let showsTemperatureTenths: Bool
    let showsIcons: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if sensors.isEmpty {
                Text("No sensors available")
                    .secondary()
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(sensors) {
                        FanMetricRow(
                            $0.displayName,
                            systemImage: showsIcons ? $0.systemImage : nil,
                            value: $0.celsius.formattedTemperature(
                                in: temperatureUnit,
                                showsTenths: showsTemperatureTenths
                            ),
                            valueColor: $0.celsius.temperatureValueColor
                        )
                    }
                }
                .monospacedDigit()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
    
    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }
}
