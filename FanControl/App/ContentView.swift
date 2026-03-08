import ScrechKit

struct ContentView: View {
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
            
            HStack(alignment: .top, spacing: 12) {
                FanControlsView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: 400, alignment: .topLeading)
                
                FanTemperatureCardView(sensors: model.temperatureSensors)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .frame(width: 280)
                    .fanCardSurface()
                    .frame(maxHeight: 400, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding()
        .frame(width: 680)
        .background(ContentViewBackground())
        .alert(item: $model.errorAlert) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                primaryButton: .default(Text("Copy error message"), action: model.copyErrorMessage),
                secondaryButton: .cancel(Text("OK"), action: model.dismissError)
            )
        }
        .alert(item: $model.mainWindowUpdateStatusAlert) { updateStatusAlert in
            Alert(
                title: Text(updateStatusAlert.title),
                message: Text(updateStatusAlert.message),
                dismissButton: .cancel(Text("OK")) {
                    model.dismissUpdateStatusAlert(for: .mainWindow)
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
