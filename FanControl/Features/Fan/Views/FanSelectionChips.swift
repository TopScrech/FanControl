import ScrechKit
import CoreSMC

struct FanSelectionChips: View {
    @Bindable var model: FanVM

    var body: some View {
        HStack(spacing: 2) {
            if model.showsAllFansOption {
                Button("All") {
                    model.selectedFanID = model.allFansID
                }
                .buttonStyle(FanSelectionChipStyle(isSelected: model.controlsAllFans))
            }

            ForEach(model.fans) { fan in
                Button("Fan \(fan.userFacingID)") {
                    select(fan)
                }
                .buttonStyle(FanSelectionChipStyle(isSelected: model.selectedFanID == fan.id))
            }
        }
        .padding(2)
        .background(.primary.opacity(0.08), in: .capsule)
        .animation(.easeInOut(duration: 0.18), value: model.selectedFanID)
    }
    
    private func select(_ fan: Fan) {
        let isReselecting = model.selectedFanID == fan.id && model.showsAllFansOption
        model.selectedFanID = isReselecting ? model.allFansID : fan.id
    }
}
