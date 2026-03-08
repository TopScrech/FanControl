import ScrechKit

struct FanActionCardView: View {
    let canSetManual: Bool
    let canUsePresets: Bool
    let presetRPMs: [Int]
    let sensors: [TemperatureSensor]
    let selectedCustomPreset: FanCustomPresetDraft
    let isCustomPresetActive: Bool
    let customPresetPercentageText: String?
    let activeMode: FanControlMode?
    let isSendingAttempts: Bool
    let setAuto: () -> Void
    let setMin: () -> Void
    let setFull: () -> Void
    let setPreset: (Int) -> Void
    let setCustomPreset: (FanCustomPresetDraft) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Label("Control", systemImage: "slider.horizontal.3")
                    .headline()
                
                Spacer(minLength: 0)
                
                if isSendingAttempts {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            
            HStack(spacing: 10) {
                if activeMode == .auto {
                    Button(action: setAuto) {
                        Label("Auto", systemImage: "fan")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: setAuto) {
                        Label("Auto", systemImage: "fan")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                
                FanPresetMenuView(
                    canUsePresets: canUsePresets,
                    presetRPMs: presetRPMs,
                    sensors: sensors,
                    selectedCustomPreset: selectedCustomPreset,
                    isCustomPresetActive: isCustomPresetActive,
                    customPresetPercentageText: customPresetPercentageText,
                    activeMode: activeMode,
                    setPreset: setPreset,
                    setCustomPreset: setCustomPreset
                )
                .frame(maxWidth: .infinity)
            }
            
            HStack(spacing: 10) {
                if activeMode == .min {
                    Button(action: setMin) {
                        Label("Min", systemImage: "arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSetManual)
                } else {
                    Button(action: setMin) {
                        Label("Min", systemImage: "arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canSetManual)
                }
                
                if activeMode == .max {
                    Button(action: setFull) {
                        Label("Max", systemImage: "arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSetManual)
                } else {
                    Button(action: setFull) {
                        Label("Max", systemImage: "arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canSetManual)
                }
            }
        }
        .controlSize(.large)
        .animation(.easeInOut(duration: 0.2), value: activeMode)
        .animation(.easeInOut(duration: 0.2), value: isSendingAttempts)
        .frame(maxHeight: .infinity, alignment: .top)
        .fanCardSurface()
    }
}
