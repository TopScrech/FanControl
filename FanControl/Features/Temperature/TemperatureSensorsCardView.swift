import ScrechKit

struct TemperatureSensorsCardView: View {
    let sensors: [TemperatureSensor]
    let temperatureUnit: TemperatureUnit
    let showsTemperatureTenths: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if sensors.isEmpty {
                Text("No sensors available")
                    .secondary()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(sensors) {
                        FanMetricRowView(
                            $0.displayName,
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
}
