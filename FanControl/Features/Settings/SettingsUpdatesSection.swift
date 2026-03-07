import ScrechKit

struct SettingsUpdatesSection: View {
    let appVersionDescription: String
    let isCheckingForUpdates: Bool
    @Binding var allowsPrereleaseUpdates: Bool
    @Binding var usesGitHubProxy: Bool
    @Binding var gitHubProxyURLString: String
    let showsResetGitHubProxyURLButton: Bool
    let defaultGitHubProxyURLString: String
    let onResetGitHubProxyURL: () -> Void
    let onCheckForUpdates: () -> Void
    
    var body: some View {
        Section {
            LabeledContent("Version", value: appVersionDescription)
            
            Toggle("Pre-release updates", isOn: $allowsPrereleaseUpdates)
            Toggle("GitHub proxy", isOn: $usesGitHubProxy)
            
            if usesGitHubProxy {
                TextField("GitHub proxy URL", text: $gitHubProxyURLString)
                    .disabled(!usesGitHubProxy)
            }
        } header: {
            HStack {
                Text("Updates")
                
                Spacer()
                
                SFButton("arrow.trianglehead.2.clockwise.rotate.90", action: onCheckForUpdates)
                    .disabled(isCheckingForUpdates)
                    .secondary()
            }
        } footer: {
            if showsResetGitHubProxyURLButton {
                Button("Reset", action: onResetGitHubProxyURL)
                    .secondary()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
