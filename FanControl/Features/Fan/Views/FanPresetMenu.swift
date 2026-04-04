import ScrechKit

struct FanPresetMenu: View {
    @Bindable var model: FanVM
    
    @State private var showsPresetMenu = false
    @State private var showsLicenseAlert = false
    
    var body: some View {
        Group {
            if model.activeControlMode == .preset || model.activeControlMode == .custom {
                Button(action: showPresetMenuOrLicenseAlert) {
                    Label(buttonTitle, systemImage: "dial.low")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("4")
            } else {
                Button(action: showPresetMenuOrLicenseAlert) {
                    Label(buttonTitle, systemImage: "dial.low")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("4")
            }
        }
        .monospacedDigit()
        .frame(maxWidth: .infinity)
        .disabled(model.controlPresetRPMs.isEmpty && model.temperatureSensors.isEmpty)
        .help(
            model.canUsePresetControl
            ? String(localized: "Preset control")
            : String(localized: "Preset control requires an active license")
        )
        .popover(isPresented: $showsPresetMenu, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                FanCustomPresetEditor(model: model) {
                    setCustomPreset($0)
                    showsPresetMenu = false
                }
                
                if !model.controlPresetRPMs.isEmpty {
                    Divider()
                        .overlay(.primary.opacity(0.18))
                    
                    FanFixedPresetList(presetRPMs: model.controlPresetRPMs) { rpm in
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
        if model.canUsePresetControl {
            showsPresetMenu.toggle()
            return
        }
        
        showsLicenseAlert = true
    }
    
    private var buttonTitle: String {
        if model.activeControlMode == .custom, let customPresetPercentageText = model.selectedCustomPresetPercentageText {
            String(localized: "Preset \(customPresetPercentageText)")
        } else {
            String(localized: "Presets")
        }
    }

    private func setPreset(_ rpm: Int) {
        Task {
            await model.setManualRPM(Double(rpm))
        }
    }

    private func setCustomPreset(_ draft: FanCustomPresetDraft) {
        Task {
            await model.setCustomPreset(draft)
        }
    }
}
