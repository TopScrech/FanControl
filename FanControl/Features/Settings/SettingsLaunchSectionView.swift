import ScrechKit
import LaunchAtLogin

struct SettingsLaunchSectionView: View {
    @AppStorage("hideWindowOnLaunch") private var hideWindowOnLaunch = false
    
    var body: some View {
        Section("Launch") {
            LaunchAtLogin.Toggle(LocalizedStringKey("Launch at login"))
            Toggle("Hide window on launch", isOn: $hideWindowOnLaunch)
        }
    }
}
