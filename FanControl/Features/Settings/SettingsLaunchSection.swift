import ScrechKit
import LaunchAtLogin

struct SettingsLaunchSection: View {
    @AppStorage("hideWindowOnLaunch") private var hideWindowOnLaunch = false
    @AppStorage("keepsWindowOnTop") private var keepsWindowOnTop = false
    @AppStorage(DockIconVisibilityController.hidesDockIconDefaultsKey) private var hidesDockIcon = false
    
    var body: some View {
        Section("Launch") {
            LaunchAtLogin.Toggle(LocalizedStringKey("Launch at login"))
            
            Toggle("Hide window on launch", isOn: $hideWindowOnLaunch)
            Toggle("Hide Dock icon", isOn: $hidesDockIcon)
            Toggle("Keep on top of other windows", isOn: $keepsWindowOnTop)
        }
        .onChange(of: hidesDockIcon, initial: true) { _, newValue in
            DockIconVisibilityController.setDockIconHidden(newValue)
        }
    }
}
