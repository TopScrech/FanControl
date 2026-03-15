import ScrechKit

struct ContentViewHeader: View {
    @Environment(\.openWindow) private var openWindow
    
    @Bindable var model: FanVM
    var showsShowWindowButton = false
    
    var body: some View {
        HStack {
            Text("FanControl")
                .title3(.semibold)
            
            if !model.isLicenseActive {
                LicenseInactiveBadge()
            }
            
            Spacer(minLength: 0)
            
            if showsShowWindowButton {
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
}

#Preview {
    ContentViewHeader(model: FanVM(), showsShowWindowButton: true)
}
