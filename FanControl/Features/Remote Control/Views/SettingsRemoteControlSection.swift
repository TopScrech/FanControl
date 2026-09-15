import ScrechKit

struct SettingsRemoteControlSection: View {
    @Bindable var model: FanVM
    
    var body: some View {
        Section {
            Toggle("Remote control", isOn: $model.isRemoteControlEnabled)
        } header: {
            HStack {
                Text("Remote control")
                
                Spacer()
                
                Text(model.remoteControlStatusText)
                    .secondary()
            }
        }
    }
}
