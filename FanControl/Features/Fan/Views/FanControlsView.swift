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
                .fanCardSurface()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
