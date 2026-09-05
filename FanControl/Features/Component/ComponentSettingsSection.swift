import SwiftUI

struct ComponentSettingsSection: View {
    @Environment(FanVM.self) private var model

    var body: some View {
        @Bindable var installer = model.componentInstaller
        Section("FanControl components") {
            if let version = model.componentVersion {
                LabeledContent("Version", value: version)
            } else {
                Text(installer.status)
                    .foregroundStyle(.secondary)
                if installer.isInstalling { ProgressView() }
                Button("Install components", systemImage: "arrow.down.circle") {
                    installer.showsInstallPrompt = true
                }
                .disabled(installer.isInstalling)
            }
        }
        .task {
            await model.reconnectComponent()
            if model.componentVersion == nil { installer.promptIfNeeded() }
        }
        .alert("Install FanControl components?", isPresented: $installer.showsInstallPrompt) {
            Button("Install") { Task { await installer.install() } }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("FanControl needs an additional background component to control fans and read temperatures. Installation is automatic; macOS may ask you to approve the component")
        }
    }
}
