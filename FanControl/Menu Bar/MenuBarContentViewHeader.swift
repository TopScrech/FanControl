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
            
            SFButton("macwindow", action: showWindow)
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
