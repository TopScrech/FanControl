import ScrechKit

struct FanControlsView: View {
    @Bindable var model: FanVM

    var showSensors = false

    var body: some View {
        VStack(spacing: 8) {
            FanPromotionsView()

            if model.fans.isEmpty {
                FanEmptyState()
            } else {
                FanSpeedCard(model: model)

                FanActionCard(model: model)
            }

            FanTemperatureCard(model: model, showAllSensors: showSensors)
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 8)
                .fanCardSurface(padding: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
