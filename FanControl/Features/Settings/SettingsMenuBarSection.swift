import SwiftUI

struct SettingsMenuBarSection: View {
    @AppStorage(FanVM.showsMenuBarFanSpeedDefaultsKey) private var showsMenuBarFanSpeed = false
    @AppStorage(FanVM.showsMenuBarAverageTemperaturesDefaultsKey) private var showsMenuBarAverageTemperatures = true
    
    var body: some View {
        Section("Menu Bar") {
            Toggle("Show fan speed next to menu bar icon", isOn: $showsMenuBarFanSpeed)
            Toggle("Average CPU and GPU temperatures", isOn: $showsMenuBarAverageTemperatures)
        }
    }
}
