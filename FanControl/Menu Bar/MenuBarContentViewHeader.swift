import ScrechKit

struct MenuBarContentViewHeader: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings
    
    @Bindable var model: FanVM
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("FanControl")
                    .title3(.semibold)
                
                if !model.isLicenseActive {
                    LicenseInactiveBadge()
                }
            }
            
            Spacer(minLength: 0)
            
            HStack {
                Button("Settings", systemImage: "gearshape", action: openAppSettings)
                    .labelStyle(.iconOnly)
                    .help("Settings")

                Button("Show window", systemImage: "macwindow", action: showWindow)
                    .labelStyle(.iconOnly)
                    .help("Show window")
            }
        }
    }
    
    private func openAppSettings() {
        let menuBarWindow = NSApplication.shared.keyWindow
        openSettings()
        NSApplication.shared.activate(ignoringOtherApps: true)
        menuBarWindow?.orderOut(nil)
    }

    private func showWindow() {
        let menuBarWindow = NSApplication.shared.keyWindow
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
        menuBarWindow?.orderOut(nil)
    }
}

#Preview {
    MenuBarContentViewHeader(model: FanVM())
}
