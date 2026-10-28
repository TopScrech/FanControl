import ScrechKit
import Appearance

struct RemoteSettings: View {
    @Environment(RemoteControlViewModel.self) private var model
    @AppStorage("appearance") private var appearance: Appearance = .system
    
    @State private var isShowingDemo = false
    
    var body: some View {
        Form {
            AppearancePicker($appearance)
            
            if !model.isDemo {
                Section {
                    Button("Demo", systemImage: "play.rectangle") {
                        isShowingDemo = true
                    }
                    .tint(.primary)
                }
            }
        }
        .navigationTitle("Settings")
        .fullScreenCover($isShowingDemo) {
            DemoMacListView()
        }
    }
}
