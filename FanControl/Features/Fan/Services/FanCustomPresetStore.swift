import Foundation
#if !SANDBOXED_APP
import CoreSMC
#endif

struct FanCustomPresetStore {
    private static let defaultsKey = "customPresets"
    
    private var presetsByFanID: [Int: FanCustomPreset]
    
    init() {
        presetsByFanID = Self.loadPresets()
    }
    
    var hasEnabledPresets: Bool {
        presetsByFanID.values.contains {
            $0.isEnabled
        }
    }
    
    var activeFanIDs: [Int] {
        presetsByFanID.values.compactMap {
            $0.isEnabled ? $0.fanID : nil
        }
    }
    
    func preset(for fanID: Int) -> FanCustomPreset? {
        presetsByFanID[fanID]
    }
    
    func draft(
        for fans: [Fan],
        selectableTemperatureSensors: [TemperatureSensor],
        defaultMinimumTemperature: Int,
        defaultMaximumTemperature: Int
    ) -> FanCustomPresetDraft {
        guard !fans.isEmpty else {
            return defaultDraft(
                selectableTemperatureSensors: selectableTemperatureSensors,
                defaultMinimumTemperature: defaultMinimumTemperature,
                defaultMaximumTemperature: defaultMaximumTemperature
            )
        }
        
        if let sharedPreset = sharedPreset(for: fans) {
            return draft(
                from: sharedPreset,
                selectableTemperatureSensors: selectableTemperatureSensors,
                defaultMinimumTemperature: defaultMinimumTemperature,
                defaultMaximumTemperature: defaultMaximumTemperature
            )
        }
        
        if let firstPreset = fans.compactMap({ preset(for: $0.id) }).first {
            return draft(
                from: firstPreset,
                selectableTemperatureSensors: selectableTemperatureSensors,
                defaultMinimumTemperature: defaultMinimumTemperature,
                defaultMaximumTemperature: defaultMaximumTemperature
            )
        }
        
        return defaultDraft(
            selectableTemperatureSensors: selectableTemperatureSensors,
            defaultMinimumTemperature: defaultMinimumTemperature,
            defaultMaximumTemperature: defaultMaximumTemperature
        )
    }
    
    func isActive(for fans: [Fan]) -> Bool {
        guard !fans.isEmpty else { return false }
        
        return fans.allSatisfy {
            preset(for: $0.id)?.isEnabled == true
        }
    }
    
    func normalizedDraft(
        _ draft: FanCustomPresetDraft,
        selectableTemperatureSensors: [TemperatureSensor]
    ) -> FanCustomPresetDraft {
        let minimumTemperature = min(
            max(draft.minimumTemperature, FanCustomPreset.temperatureBounds.lowerBound),
            FanCustomPreset.temperatureBounds.upperBound
        )
        let maximumTemperature = min(
            max(draft.maximumTemperature, minimumTemperature),
            FanCustomPreset.temperatureBounds.upperBound
        )
        let sensorKey = resolvedSensorKey(
            preferred: draft.sensorKey,
            selectableTemperatureSensors: selectableTemperatureSensors
        ) ?? ""
        
        return FanCustomPresetDraft(
            sensorKey: sensorKey,
            minimumTemperature: minimumTemperature,
            maximumTemperature: maximumTemperature
        )
    }
    
    func resolvedTemperatureSensor(
        for sensorKey: String,
        selectableTemperatureSensors: [TemperatureSensor]
    ) -> TemperatureSensor? {
        if let matchedSensor = selectableTemperatureSensors.first(where: { $0.key == sensorKey }) {
            matchedSensor
        } else {
            selectableTemperatureSensors.first
        }
    }
    
    mutating func storeConfiguration(
        fanIDs: [Int],
        sensor: TemperatureSensor,
        draft: FanCustomPresetDraft,
        isEnabled: Bool
    ) {
        for fanID in fanIDs {
            presetsByFanID[fanID] = FanCustomPreset(
                fanID: fanID,
                sensorKey: sensor.key,
                sensorDisplayName: sensor.displayName,
                minimumTemperature: draft.minimumTemperature,
                maximumTemperature: draft.maximumTemperature,
                isEnabled: isEnabled
            )
        }
        
        persistPresets()
    }
    
    mutating func setEnabled(_ isEnabled: Bool, fanIDs: [Int]) {
        var needsSave = false
        
        for fanID in fanIDs {
            guard var preset = presetsByFanID[fanID] else { continue }
            guard preset.isEnabled != isEnabled else { continue }
            preset.isEnabled = isEnabled
            presetsByFanID[fanID] = preset
            needsSave = true
        }
        
        if needsSave {
            persistPresets()
        }
    }
    
    func targetRPM(
        for fan: Fan,
        sensorTemperature: Double,
        minimumTemperature: Int,
        maximumTemperature: Int
    ) -> Double {
        let minimumRPM = fan.minRPM
        let maximumRPM = fan.maxRPM
        let minimumTemperature = Double(minimumTemperature)
        let maximumTemperature = Double(maximumTemperature)
        
        if sensorTemperature <= minimumTemperature {
            return minimumRPM
        }
        
        if maximumTemperature <= minimumTemperature || sensorTemperature >= maximumTemperature {
            return maximumRPM
        }
        
        let progress = (sensorTemperature - minimumTemperature) / (maximumTemperature - minimumTemperature)
        let interpolatedRPM = minimumRPM + progress * (maximumRPM - minimumRPM)
        return min(max(interpolatedRPM.rounded(), minimumRPM), maximumRPM)
    }
    
    private func sharedPreset(for fans: [Fan]) -> FanCustomPreset? {
        let presets = fans.compactMap {
            preset(for: $0.id)
        }
        
        guard presets.count == fans.count, let firstPreset = presets.first else { return nil }
        
        guard presets.allSatisfy({
            $0.sensorKey == firstPreset.sensorKey &&
            $0.minimumTemperature == firstPreset.minimumTemperature &&
            $0.maximumTemperature == firstPreset.maximumTemperature &&
            $0.isEnabled == firstPreset.isEnabled
        }) else {
            return nil
        }
        
        return firstPreset
    }
    
    private func defaultDraft(
        selectableTemperatureSensors: [TemperatureSensor],
        defaultMinimumTemperature: Int,
        defaultMaximumTemperature: Int
    ) -> FanCustomPresetDraft {
        FanCustomPresetDraft(
            sensorKey: selectableTemperatureSensors.first?.key ?? "",
            minimumTemperature: defaultMinimumTemperature,
            maximumTemperature: defaultMaximumTemperature
        )
    }
    
    private func draft(
        from preset: FanCustomPreset,
        selectableTemperatureSensors: [TemperatureSensor],
        defaultMinimumTemperature: Int,
        defaultMaximumTemperature: Int
    ) -> FanCustomPresetDraft {
        let defaultDraft = defaultDraft(
            selectableTemperatureSensors: selectableTemperatureSensors,
            defaultMinimumTemperature: defaultMinimumTemperature,
            defaultMaximumTemperature: defaultMaximumTemperature
        )
        let sensorKey = resolvedSensorKey(
            preferred: preset.sensorKey,
            selectableTemperatureSensors: selectableTemperatureSensors
        ) ?? defaultDraft.sensorKey
        
        return FanCustomPresetDraft(
            sensorKey: sensorKey,
            minimumTemperature: preset.minimumTemperature,
            maximumTemperature: preset.maximumTemperature
        )
    }
    
    private func resolvedSensorKey(
        preferred sensorKey: String,
        selectableTemperatureSensors: [TemperatureSensor]
    ) -> String? {
        if selectableTemperatureSensors.contains(where: { $0.key == sensorKey }) {
            sensorKey
        } else {
            selectableTemperatureSensors.first?.key
        }
    }
    
    private static func loadPresets() -> [Int: FanCustomPreset] {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey) else {
            return [:]
        }
        
        guard let presets = try? JSONDecoder().decode([FanCustomPreset].self, from: data) else {
            return [:]
        }
        
        return Dictionary(uniqueKeysWithValues: presets.map { ($0.fanID, $0) })
    }
    
    private func persistPresets() {
        let presets = presetsByFanID.values.sorted {
            $0.fanID < $1.fanID
        }
        
        guard let data = try? JSONEncoder().encode(presets) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
