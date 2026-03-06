import ScrechKit

struct FanControlsView: View {
    @Bindable var model: FanVM
    
    var body: some View {
        VStack(spacing: 12) {
            if model.fans.isEmpty {
                FanEmptyStateView()
            } else {
                FanPickerCardView(
                    fans: model.fans,
                    allFansID: model.allFansID,
                    showsAllFansOption: model.showsAllFansOption,
                    selectedFanID: $model.selectedFanID
                )
                
                if model.controlsAllFans {
                    AllFansCurrentSpeedCardView(fans: model.fans)
                } else if let fan = model.selectedFan {
                    FanDetailsCardView(fan: fan)
                }
                
                FanActionCardView(
                    canSetManual: model.controlMinRPM != nil && model.controlMaxRPM != nil,
                    canUsePresets: model.canUsePresetControl,
                    presetRPMs: model.controlPresetRPMs,
                    sensors: model.temperatureSensors,
                    selectedCustomPreset: model.selectedCustomPresetDraft,
                    isCustomPresetActive: model.selectedCustomPresetIsActive,
                    customPresetPercentageText: model.selectedCustomPresetPercentageText,
                    activeMode: model.activeControlMode,
                    isSendingAttempts: model.showsControlAttemptProgress
                ) {
                    Task { await model.setAuto() }
                } setMin: {
                    Task { await model.setControlMin() }
                } setFull: {
                    Task { await model.setControlMax() }
                } setPreset: { rpm in
                    Task { await model.setManualRPM(Double(rpm)) }
                } setCustomPreset: { draft in
                    Task { await model.setCustomPreset(draft) }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
