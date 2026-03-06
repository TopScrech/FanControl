import ScrechKit

struct FanTemperatureCardView: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    
    let sensors: [TemperatureSensor]
    
    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }
    
    private var temperaturePrecision: TemperaturePrecision {
        TemperaturePrecision(rawValue: temperaturePrecisionRawValue) ?? .whole
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Label("Sensors", systemImage: "thermometer.medium")
                    .headline()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(averageRows) {
                    FanMetricRowView($0.title, value: $0.value)
                }
            }
            .monospacedDigit()
            
            VStack(alignment: .leading, spacing: 8) {
                if sensors.isEmpty {
                    Text("No sensors available")
                        .secondary()
                } else {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(sensors) {
                            FanMetricRowView(
                                $0.displayName,
                                value: $0.celsius.formattedTemperature(
                                    in: temperatureUnit,
                                    showsTenths: temperaturePrecision.showsTenths
                                )
                            )
                        }
                    }
                    .monospacedDigit()
                }
            }
        }
        .fanCardSurface()
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
}
