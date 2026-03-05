import ScrechKit

struct SettingsUpdatesSectionView: View {
    let appVersionDescription: String
    let isCheckingForUpdates: Bool
    @Binding var allowsPrereleaseUpdates: Bool
    let onCheckForUpdates: () -> Void
    
    var body: some View {
        Section {
            LabeledContent("Version", value: appVersionDescription)
            Toggle("Pre-release updates", isOn: $allowsPrereleaseUpdates)
        } header: {
            HStack {
                Text("Updates")
                
                Spacer()
                
                SFButton("arrow.trianglehead.2.clockwise.rotate.90", action: onCheckForUpdates)
                    .disabled(isCheckingForUpdates)
                    .secondary()
            }
        }
    }
}
