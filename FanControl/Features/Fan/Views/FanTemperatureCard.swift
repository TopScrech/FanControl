import ScrechKit

struct FanTemperatureCard: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    @AppStorage("showsTemperatureSensorIcons") private var showsTemperatureSensorIcons = false
    
    @Bindable var model: FanVM
    var showAllSensors = true
    
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
                    FanMetricRow(
                        $0.title,
                        systemImage: showsTemperatureSensorIcons ? $0.systemImage : nil,
                        value: $0.value
                    )
                }
            }
            .monospacedDigit()
            
            if showAllSensors {
                Divider()
                    .overlay(.primary.opacity(0.22))
                
                if model.temperatureSensors.isEmpty {
                    Text("No sensors available")
                        .secondary()
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(model.temperatureSensors) {
                                FanMetricRow(
                                    $0.displayName,
                                    systemImage: showsTemperatureSensorIcons ? $0.systemImage : nil,
                                    value: $0.celsius.formattedTemperature(
                                        in: temperatureUnit,
                                        showsTenths: temperaturePrecision.showsTenths
                                    ),
                                    valueColor: $0.celsius.temperatureValueColor
                                )
                            }
                        }
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private var averageRows: [TemperatureAverageRow] {
        TemperatureSensorCategory.averageCases(isMacBook: model.isMacBook).map { category in
            let values = model.temperatureSensors
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
                systemImage: category.systemImage,
                value: averageText
            )
        }
    }
}
