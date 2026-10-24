import ScrechKit
import CoreSMC

struct FanPresetMenu: View {
    @Bindable var model: FanVM
    
    @State private var showsPresetMenu = false
    @State private var showsLicenseAlert = false
    
    var body: some View {
        Button(action: showPresetMenuOrLicenseAlert) {
            Label(buttonTitle, systemImage: "dial.low")
        }
        .buttonStyle(FanModeButtonStyle(isActive: model.activeControlMode == .preset || model.activeControlMode == .custom))
        .keyboardShortcut("4")
        .monospacedDigit()
        .frame(maxWidth: .infinity)
        .disabled(model.controlPresetRPMs.isEmpty && model.temperatureSensors.isEmpty)
        .help(
            model.canUsePresetControl
            ? Text("Preset control")
            : Text("Preset control requires an active license")
        )
        .popover(isPresented: $showsPresetMenu, arrowEdge: .bottom) {
            VStack(spacing: 8) {
                FanCustomPresetEditor(model: model) {
                    setCustomPreset($0)
                    showsPresetMenu = false
                }
                .fanCardSurface()
                
                if !model.controlPresetRPMs.isEmpty {
                    FanFixedPresetList(presetRPMs: model.controlPresetRPMs, activeRPM: activePresetRPM) { rpm in
                        setPreset(rpm)
                        showsPresetMenu = false
                    }
                    .fanCardSurface()
                }
            }
            .padding(8)
            .frame(width: 320)
        }
        .alert("License required", isPresented: $showsLicenseAlert) {
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
    
    private var activePresetRPM: Int? {
        guard model.activeControlMode == .preset, let fan = model.selectedFan ?? model.fans.first else {
            return nil
        }
        
        return model.controlPresetRPMs.min {
            abs(Double($0) - fan.targetRPM) < abs(Double($1) - fan.targetRPM)
        }
    }
    
    private var buttonTitle: LocalizedStringKey {
        if model.activeControlMode == .custom, let customPresetPercentageText = model.selectedCustomPresetPercentageText {
            "Preset \(customPresetPercentageText)"
        } else {
            "Presets"
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
