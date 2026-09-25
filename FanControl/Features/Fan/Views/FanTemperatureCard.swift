import ScrechKit

struct FanTemperatureCard: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    @AppStorage("showsTemperatureSensorIcons") private var showsTemperatureSensorIcons = false

    @Bindable var model: FanVM

    @State private var isExpanded: Bool

    init(model: FanVM, showAllSensors: Bool = true) {
        self.model = model
        _isExpanded = State(initialValue: showAllSensors)
    }

    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }

    private var temperaturePrecision: TemperaturePrecision {
        TemperaturePrecision(rawValue: temperaturePrecisionRawValue) ?? .whole
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text("Sensors")
                    .headline()

                Spacer(minLength: 0)

                Button(action: toggleExpanded) {
                    HStack(spacing: 3) {
                        Text(isExpanded ? "Show less" : "View all")

                        Image(systemName: "chevron.down")
                            .imageScale(.small)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .buttonStyle(.plain)
                .footnote(.medium)
                .secondary()
                .disabled(model.temperatureSensors.isEmpty)
            }

            VStack(spacing: 0) {
                let rows = averageRows
                
                ForEach(rows) { row in
                    FanSensorRow(
                        title: row.title,
                        systemImage: showsTemperatureSensorIcons ? row.systemImage : nil,
                        value: row.value,
                        celsius: row.celsius,
                        showsSeparator: row.id != rows.first?.id
                    )
                }

                if isExpanded {
                    ForEach(model.temperatureSensors.sorted()) {
                        FanSensorRow(
                            title: $0.displayName,
                            systemImage: showsTemperatureSensorIcons ? $0.systemImage : nil,
                            value: $0.celsius.formattedTemperature(
                                in: temperatureUnit,
                                showsTenths: temperaturePrecision.showsTenths
                            ),
                            celsius: $0.celsius,
                            showsSeparator: true
                        )
                    }
                    .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func toggleExpanded() {
        withAnimation(.smooth(duration: 0.32)) {
            isExpanded.toggle()
        }
    }

    private var averageRows: [TemperatureAverageRow] {
        TemperatureSensorCategory.averageCases(isMacBook: model.isMacBook).map { category in
            let average = category.averageCelsius(in: model.temperatureSensors)

            return TemperatureAverageRow(
                id: category.rawValue,
                title: category.title,
                systemImage: category.systemImage,
                value: average?.formattedTemperature(in: temperatureUnit, showsTenths: temperaturePrecision.showsTenths) ?? "--",
                celsius: average
            )
        }
    }
}
