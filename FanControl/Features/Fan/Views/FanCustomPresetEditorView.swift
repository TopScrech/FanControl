import ScrechKit

struct FanCustomPresetEditorView: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    
    let model: FanVM
    let applyPreset: (FanCustomPresetDraft) -> Void
    
    @State private var draft: FanCustomPresetDraft
    
    init(
        model: FanVM,
        applyPreset: @escaping (FanCustomPresetDraft) -> Void
    ) {
        self.model = model
        self.applyPreset = applyPreset
        _draft = State(initialValue: model.selectedCustomPresetDraft)
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
                
                Button(isActive ? "Update" : "Apply", action: applyCurrentDraft)
                    .buttonStyle(.borderedProminent)
            }
        }
        .onChange(of: model.selectedCustomPresetDraft, initial: true) { _, newValue in
            draft = normalized(newValue)
        }
        .onChange(of: model.temperatureSensors, initial: true) {
            draft = normalized(draft)
        }
    }
    
    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }
    
    private var temperaturePrecision: TemperaturePrecision {
        TemperaturePrecision(rawValue: temperaturePrecisionRawValue) ?? .whole
    }
    
    private var sensors: [TemperatureSensor] {
        model.temperatureSensors
    }
    
    private var isActive: Bool {
        model.selectedCustomPresetIsActive
    }
    
    private var pickerSensors: [TemperatureSensor] {
        averagePickerSensors + sensors
    }
    
    private var averagePickerSensors: [TemperatureSensor] {
        TemperatureSensorCategory.averageCases(isMacBook: model.isMacBook).compactMap {
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
