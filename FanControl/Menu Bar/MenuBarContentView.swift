import ScrechKit

struct MenuBarContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    
    @Bindable var model: FanVM
    let showsHideWindowButton: Bool
    let showsUpdateAlert: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("FanControl")
                    .title3(.semibold)
                
                if showsHideWindowButton && !model.isLicenseActive {
                    Button("License inactive", action: openLicenseSettings)
                        .caption()
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.orange)
                        .background(.orange.opacity(0.16), in: .capsule)
                        .buttonStyle(.plain)
                }
                
                Spacer(minLength: 0)
                
                if showsHideWindowButton {
                    Button("Hide window", systemImage: "eye.slash", action: hideWindow)
                } else {
                    Button("Show window", systemImage: "macwindow", action: showWindow)
                }
            }
            .controlSize(.small)
            
            FanControlsView(model: model, showSensors: true)
                .frame(maxWidth: .infinity, maxHeight: 400, alignment: .topLeading)
        }
        .padding()
        .frame(width: 340)
        .frame(minHeight: 515, alignment: .top)
        .background(ContentViewBackground())
        .alert(item: $model.errorAlert) { errorAlert in
            Alert(
                title: Text("Error"),
                message: Text(errorAlert.message),
                primaryButton: .default(Text("Copy error message"), action: model.copyErrorMessage),
                secondaryButton: .cancel(Text("OK"), action: model.dismissError)
            )
        }
        .alert(item: $model.menuBarUpdateStatusAlert) { updateStatusAlert in
            Alert(
                title: Text(updateStatusAlert.title),
                message: Text(updateStatusAlert.message),
                dismissButton: .cancel(Text("OK")) {
                    model.dismissUpdateStatusAlert(for: .menuBar)
                }
            )
        }
        .sheet(showsUpdateAlert && !model.isSettingsOpen ? $model.isUpdatePromptPresented : .constant(false)) {
            UpdateSheetView(
                title: model.updatePromptTitle,
                changelogEntries: model.updateChangelogEntries,
                isInstalling: model.isCheckingForUpdates,
                onNotNow: cancelUpdate,
                onUpdate: installPreparedUpdate
            )
        }
    }
    
    private func installPreparedUpdate() {
        Task {
            await model.installPreparedUpdate()
        }
    }
    
    private func cancelUpdate() {
        Task {
            await model.dismissUpdatePrompt()
        }
    }
    
    private func showWindow() {
        let menuBarWindow = NSApplication.shared.keyWindow
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
        menuBarWindow?.orderOut(nil)
    }
    
    private func hideWindow() {
        NSApplication.shared.keyWindow?.orderOut(nil)
    }
    
    private func openLicenseSettings() {
        openSettings()
    }
}
