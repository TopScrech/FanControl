import ScrechKit
import CoreSMC

struct FanPickerCardView: View {
    let fans: [Fan]
    let allFansID: Int
    let showsAllFansOption: Bool
    @Binding var selectedFanID: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Fans", systemImage: "fanblades")
                .headline()
            
            Picker("Fan", selection: $selectedFanID) {
                if showsAllFansOption {
                    Text("All")
                        .tag(allFansID)
                }
                
                ForEach(fans) {
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
