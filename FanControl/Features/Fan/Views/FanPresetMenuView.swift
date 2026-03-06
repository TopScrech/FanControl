import ScrechKit

struct FanPresetMenuView: View {
    let canUsePresets: Bool
    let presetRPMs: [Int]
    let sensors: [TemperatureSensor]
    let selectedCustomPreset: FanCustomPresetDraft
    let isCustomPresetActive: Bool
    let customPresetPercentageText: String?
    let activeMode: FanControlMode?
    let setPreset: (Int) -> Void
    let setCustomPreset: (FanCustomPresetDraft) -> Void
    
    @State private var showsPresetMenu = false
    @State private var showsLicenseAlert = false
    
    var body: some View {
        Group {
            if activeMode == .preset || activeMode == .custom {
                Button(action: showPresetMenuOrLicenseAlert) {
                    Label(buttonTitle, systemImage: "dial.low")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: showPresetMenuOrLicenseAlert) {
                    Label(buttonTitle, systemImage: "dial.low")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .disabled(presetRPMs.isEmpty && sensors.isEmpty)
        .help(
            canUsePresets
            ? String(localized: "Preset control")
            : String(localized: "Preset control requires an active license")
        )
        .popover(isPresented: $showsPresetMenu, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                FanCustomPresetEditorView(
                    sensors: sensors,
                    initialDraft: selectedCustomPreset,
                    isActive: isCustomPresetActive
                ) { draft in
                    setCustomPreset(draft)
                    showsPresetMenu = false
                }
                
                if !presetRPMs.isEmpty {
                    Divider()
                        .overlay(.primary.opacity(0.18))
                    
                    FanFixedPresetListView(presetRPMs: presetRPMs) { rpm in
                        setPreset(rpm)
                        showsPresetMenu = false
                    }
                }
            }
            .padding()
            .frame(width: 320)
        }
        .alert(String(localized: "License required"), isPresented: $showsLicenseAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Activate your license in Settings to use presets")
        }
    }
    
    private func showPresetMenuOrLicenseAlert() {
        if canUsePresets {
            showsPresetMenu.toggle()
            return
        }
        
        showsLicenseAlert = true
    }
    
    private var buttonTitle: String {
        if activeMode == .custom, let customPresetPercentageText {
            return "Preset \(customPresetPercentageText)"
        }
        
        return "Preset"
    }
}
