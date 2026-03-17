import ScrechKit
import CoreSMC

struct FanPickerCardView: View {
    @Bindable var model: FanVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Fans", systemImage: "fanblades")
                .headline()
            
            Picker("Fan", selection: $model.selectedFanID) {
                if model.showsAllFansOption {
                    Text("All")
                        .tag(model.allFansID)
                }
                
                ForEach(model.fans) {
                    fanLabel($0)
                        .tag($0.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
        .fanCardSurface()
    }
    
    private func fanLabel(_ fan: Fan) -> Text {
        Text("Fan") + Text(" \(fan.userFacingID)")
    }
}
