import ScrechKit
import CoreSMC

struct FanSpeedCard: View {
    @Bindable var model: FanVM

    var body: some View {
        VStack(spacing: 0) {
            ForEach(model.fans) { fan in
                if fan.id != model.fans.first?.id {
                    Divider()
                }

                FanSpeedRow(fan: fan, isSelected: isSelected(fan)) {
                    select(fan)
                }
            }
        }
        .fanCardSurface(padding: 0)
        .clipShape(.rect(cornerRadius: 18))
        .animation(.easeInOut(duration: 0.25), value: model.selectedFanID)
    }

    private func isSelected(_ fan: Fan) -> Bool {
        model.controlsAllFans || model.selectedFanID == fan.id
    }

    private func select(_ fan: Fan) {
        guard model.showsAllFansOption else { return }
        model.selectedFanID = model.selectedFanID == fan.id ? model.allFansID : fan.id
    }
}
