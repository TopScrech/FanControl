import ScrechKit

struct MenuBarContentViewHeader: View {
    @Environment(\.openWindow) private var openWindow
    
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
            
            Button("Show window", systemImage: "macwindow", action: showWindow)
                .labelStyle(.iconOnly)
                .help("Show window")
        }
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
