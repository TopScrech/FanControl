import ScrechKit

struct SettingsPowerSection: View {
    @AppStorage(FanVM.disablesFanControlOnSleepDefaultsKey) private var disablesFanControlOnSleep = false
    
    var body: some View {
        Section("Power") {
            Toggle("Disable on sleep", isOn: $disablesFanControlOnSleep)
        }
    }
}
