import SwiftUI

struct ComponentSettingsSection: View {
    @Environment(FanVM.self) private var model
    @Environment(ComponentInstaller.self) private var componentInstaller

    var body: some View {
        @Bindable var installer = componentInstaller
        Section("FanControl components") {
            if let version = model.componentVersion {
                LabeledContent("Version", value: version)
            } else {
                Text(installer.status)
                    .foregroundStyle(.secondary)
                if installer.isInstalling { ProgressView() }
                Text(model.componentStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Install components", systemImage: "arrow.down.circle") {
                    installer.showsInstallPrompt = true
                }
                .disabled(installer.isInstalling)
            }
            if model.componentVersion != nil {
                Button("Install or update components", systemImage: "arrow.down.circle") {
                    installer.showsInstallPrompt = true
                }
                .disabled(installer.isInstalling)
                if installer.isInstalling || installer.phase == .failed { Text(installer.status) }
            }
            Button("Check connection", systemImage: "arrow.clockwise") {
                Task { await model.reconnectComponent() }
            }
            .disabled(installer.isInstalling)
        }
        .task {
            guard !installer.isInstalling else { return }
            await model.reconnectComponent()
            if model.componentVersion == nil { installer.promptIfNeeded() }
        }
        .alert("Install FanControl components?", isPresented: $installer.showsInstallPrompt) {
            Button("Install") {
                Task {
                    await installer.install()
                    await model.reconnectComponent()
                }
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("FanControl needs an additional background component to control fans and read temperatures. Installation is automatic; macOS may ask you to approve the component")
        }
    }
}
