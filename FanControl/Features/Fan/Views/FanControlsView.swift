import ScrechKit

struct FanControlsView: View {
    @Bindable var model: FanVM
    
    var body: some View {
        ScrollView {
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
                    
                    FanTemperatureCardView(sensors: model.temperatureSensors)
                    
                    FanActionCardView(
                        canSetManual: model.controlMinRPM != nil && model.controlMaxRPM != nil,
                        presetRPMs: model.controlPresetRPMs,
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
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
