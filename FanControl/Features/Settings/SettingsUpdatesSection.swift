import ScrechKit

struct SettingsUpdatesSection: View {
    @Bindable var model: FanVM
    
    var body: some View {
        Section {
            LabeledContent("Version", value: model.appVersionDescription)
            
            Toggle("Pre-release updates", isOn: $model.allowsPrereleaseUpdates)
            Toggle("GitHub proxy", isOn: $model.usesGitHubProxy)
            
            if model.usesGitHubProxy {
                TextField("GitHub proxy URL", text: $model.gitHubProxyURLString)
                    .disabled(!model.usesGitHubProxy)
            }
        } header: {
            HStack {
                Text("Updates")
                
                Spacer()
                
                Button(action: checkForUpdates) {
                    HStack {
                        Text("Check for updates")
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                }
                .disabled(model.isCheckingForUpdates)
                .secondary()
            }
        } footer: {
            if model.showsResetGitHubProxyURLButton {
                Button("Reset", action: model.resetGitHubProxyURL)
                    .secondary()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    private func checkForUpdates() {
        Task {
            await model.checkForUpdatesNow(presenter: .settings)
        }
    }
}
