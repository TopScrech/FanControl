import ScrechKit

struct SettingsUpdatesSectionView: View {
    let appVersionDescription: String
    let isCheckingForUpdates: Bool
    let onCheckForUpdates: () -> Void
    
    var body: some View {
        Section {
            LabeledContent("Version", value: appVersionDescription)
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
