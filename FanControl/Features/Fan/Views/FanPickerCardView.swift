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
                    Text($0.localizedDisplayName)
                        .tag($0.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
        .fanCardSurface()
    }
}
