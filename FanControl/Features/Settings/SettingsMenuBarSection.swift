import SwiftUI

struct SettingsMenuBarSection: View {
    @AppStorage(FanVM.showsMenuBarFanSpeedDefaultsKey) private var showsMenuBarFanSpeed = false
    @AppStorage(FanVM.showsMenuBarAverageTemperaturesDefaultsKey) private var showsMenuBarAverageTemperatures = true
    
    var body: some View {
        Section("Menu Bar") {
            Toggle("Show fan speed next to menu bar icon", isOn: $showsMenuBarFanSpeed)
            Toggle("Show average CPU and GPU temperatures as a separate menu bar item", isOn: $showsMenuBarAverageTemperatures)
        }
    }
}
