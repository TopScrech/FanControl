import ScrechKit

struct FanControlsView: View {
    @Bindable var model: FanVM
    
    var showSensors = false
    
    var body: some View {
        VStack(spacing: 12) {
            if model.fans.isEmpty {
                FanEmptyState()
            } else {
                FanPickerCard(model: model)
                
                if model.controlsAllFans {
                    AllFansCurrentSpeedCard(fans: model.fans)
                } else if let fan = model.selectedFan {
                    FanDetailsCard(fan: fan)
                }
                
                FanActionCard(model: model)
            }
            
            FanTemperatureCard(model: model, showAllSensors: showSensors)
                .frame(maxWidth: showSensors ? 280 : .infinity, alignment: .topLeading)
                .fanCardSurface()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
