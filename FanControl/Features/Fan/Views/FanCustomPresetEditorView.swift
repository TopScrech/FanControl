import ScrechKit

struct FanCustomPresetEditorView: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    
    let sensors: [TemperatureSensor]
    let initialDraft: FanCustomPresetDraft
    let isActive: Bool
    let applyPreset: (FanCustomPresetDraft) -> Void
    
    @State private var draft: FanCustomPresetDraft
    
    init(
        sensors: [TemperatureSensor],
        initialDraft: FanCustomPresetDraft,
        isActive: Bool,
        applyPreset: @escaping (FanCustomPresetDraft) -> Void
    ) {
        self.sensors = sensors
        self.initialDraft = initialDraft
        self.isActive = isActive
        self.applyPreset = applyPreset
        _draft = State(initialValue: initialDraft)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Custom preset")
                    .headline()
                
                if isActive {
                    Text("Active")
                        .caption()
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(Color.accentColor)
                        .background(Color.accentColor.opacity(0.14), in: .capsule)
                }
            }
            
            if sensors.isEmpty {
                Text("No temperature sensors available")
                    .secondary()
            } else {
                Picker("Sensor", selection: $draft.sensorKey) {
                    ForEach(sensors) {
                        Text(sensorLabel($0))
                            .tag($0.key)
                    }
                }
                
                TemperatureRangeSliderView(
                    bounds: FanCustomPreset.temperatureBounds,
                    minimumValue: $draft.minimumTemperature,
                    maximumValue: $draft.maximumTemperature
                )
                
                Button(
                    isActive ? "Update custom preset" : "Apply custom preset",
                    systemImage: "thermometer.medium",
                    action: applyCurrentDraft
                )
                .buttonStyle(.borderedProminent)
            }
        }
        .onChange(of: initialDraft, initial: true) { _, newValue in
            draft = normalized(newValue)
        }
        .onChange(of: sensors, initial: true) {
            draft = normalized(draft)
        }
    }
    
    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }
    
    private var temperaturePrecision: TemperaturePrecision {
        TemperaturePrecision(rawValue: temperaturePrecisionRawValue) ?? .whole
    }

    private func applyCurrentDraft() {
        applyPreset(normalized(draft))
    }
    
    private func normalized(_ draft: FanCustomPresetDraft) -> FanCustomPresetDraft {
        let minimumTemperature = min(
            max(draft.minimumTemperature, FanCustomPreset.temperatureBounds.lowerBound),
            FanCustomPreset.temperatureBounds.upperBound
        )
        let maximumTemperature = min(
            max(draft.maximumTemperature, minimumTemperature),
            FanCustomPreset.temperatureBounds.upperBound
        )
        let sensorKey =
        sensors.first(where: { $0.key == draft.sensorKey })?.key ??
        sensors.first?.key ??
        ""
        
        return FanCustomPresetDraft(
            sensorKey: sensorKey,
            minimumTemperature: minimumTemperature,
            maximumTemperature: maximumTemperature
        )
    }
    
    private func sensorLabel(_ sensor: TemperatureSensor) -> String {
        let temperature = sensor.celsius.formattedTemperature(
            in: temperatureUnit,
            showsTenths: temperaturePrecision.showsTenths
        )
        
        return "\(sensor.displayName) (\(temperature))"
    }
}
