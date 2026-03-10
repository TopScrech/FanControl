import ScrechKit
import LaunchAtLogin

struct SettingsLaunchSection: View {
    @AppStorage("hideWindowOnLaunch") private var hideWindowOnLaunch = false
    @AppStorage("keepsWindowOnTop") private var keepsWindowOnTop = false
    
    var body: some View {
        Section("Launch") {
            LaunchAtLogin.Toggle(LocalizedStringKey("Launch at login"))
            
            Toggle("Hide window on launch", isOn: $hideWindowOnLaunch)
            Toggle("Keep on top of other windows", isOn: $keepsWindowOnTop)
        }
    }
}
