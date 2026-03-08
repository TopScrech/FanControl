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
            Text("Custom preset")
                .headline()
            
            if sensors.isEmpty {
                Text("No temperature sensors available")
                    .secondary()
            } else {
                Picker("Sensor", selection: $draft.sensorKey) {
                    Section("Averages") {
                        ForEach(averagePickerSensors) {
                            Text(sensorLabel($0))
                                .tag($0.key)
                        }
                    }
                    
                    Section("Sensors") {
                        ForEach(sensors) {
                            Text(sensorLabel($0))
                                .tag($0.key)
                        }
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
    
    private var pickerSensors: [TemperatureSensor] {
        averagePickerSensors + sensors
    }
    
    private var averagePickerSensors: [TemperatureSensor] {
        TemperatureSensorCategory.allCases.compactMap {
            $0.averageSensor(in: sensors)
        }
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
        pickerSensors.first(where: { $0.key == draft.sensorKey })?.key ??
        pickerSensors.first?.key ??
        ""
        
        return FanCustomPresetDraft(
            sensorKey: sensorKey,
            minimumTemperature: minimumTemperature,
            maximumTemperature: maximumTemperature
        )
    }
    
    private func sensorLabel(_ sensor: TemperatureSensor) -> String {
        let displayName = pickerDisplayName(for: sensor)
        let temperature = sensor.celsius.formattedTemperature(
            in: temperatureUnit,
            showsTenths: temperaturePrecision.showsTenths
        )
        
        return "\(displayName) (\(temperature))"
    }
    
    private func pickerDisplayName(for sensor: TemperatureSensor) -> String {
        if let category = TemperatureSensorCategory.allCases.first(where: { $0.sensorKey == sensor.key }) {
            switch category {
            case .cpu: return "CPU"
            case .gpu: return "GPU"
            case .battery: return "Battery"
            }
        }
        
        return sensor.displayName
    }
}
