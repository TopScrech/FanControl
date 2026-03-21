import SwiftUI

struct SettingsMenuBarSection: View {
    @AppStorage(FanVM.showsMenuBarFanSpeedDefaultsKey) private var showsMenuBarFanSpeed = false
    
    var body: some View {
        Section("Menu Bar") {
            Toggle("Show fan speed next to menu bar icon", isOn: $showsMenuBarFanSpeed)
        }
    }
}
