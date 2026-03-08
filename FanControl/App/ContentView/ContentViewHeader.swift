import ScrechKit

struct ContentViewHeader: View {
    @Environment(\.openWindow) private var openWindow
    
    @Bindable var model: FanVM
    let showsHideWindowButton: Bool
    
    var body: some View {
        HStack {
            Text("FanControl")
                .title3(.semibold)
            
            if showsHideWindowButton && !model.isLicenseActive {
                LicenseInactiveBadge()
            }
            
            Spacer(minLength: 0)
            
            if showsHideWindowButton {
                Button("Hide window", systemImage: "eye.slash", action: hideWindow)
            } else {
                Button("Show window", systemImage: "macwindow", action: showWindow)
            }
        }
        .controlSize(.small)
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
}

#Preview {
    ContentViewHeader(model: FanVM(), showsHideWindowButton: true)
}
