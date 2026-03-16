import ScrechKit

struct FanControlsView: View {
    @Bindable var model: FanVM
    
    var showSensors = false
    
    var body: some View {
        VStack(spacing: 12) {
            if model.fans.isEmpty {
                FanEmptyStateView()
            } else {
                FanPickerCardView(model: model)
                
                if model.controlsAllFans {
                    AllFansCurrentSpeedCardView(fans: model.fans)
                } else if let fan = model.selectedFan {
                    FanDetailsCardView(fan: fan)
                }
                
                FanActionCardView(model: model)
            }
            
            if showSensors {
                FanTemperatureCardView(model: model, showAllSensors: false)
                    .frame(width: 280)
                    .fanCardSurface()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
