import ScrechKit

struct ContentView: View {
    @Bindable var model: FanVM
    
    var body: some View {
        VStack(spacing: 14) {
            if let error = model.errorText {
                FanErrorBannerView(error: error)
            }
            
            if model.fans.isEmpty {
                FanEmptyStateView()
            } else {
                FanPickerCardView(
                    fans: model.fans,
                    selectedFanID: $model.selectedFanID
                )
                
                if let fan = model.selectedFan {
                    FanDetailsCardView(fan: fan)
                    
                    FanActionCardView {
                        Task { await model.setAuto() }
                    } setMin: {
                        Task { await model.setManualRPM(fan.minRPM) }
                    } setFull: {
                        Task { await model.setManualRPM(fan.maxRPM) }
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 430)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
