import ScrechKit
import CoreSMC

struct FanSpeedControl: View {
    @Environment(FanVM.self) private var model

    let fan: Fan
    let isSelected: Bool

    var body: some View {
        if model.isLicenseActive, fan.minRPM < fan.maxRPM {
            FanSpeedSlider(fan: fan, isSelected: isSelected)
        } else {
            FanSpeedProgressView(
                currentRPM: fan.currentRPM,
                minRPM: fan.minRPM,
                maxRPM: fan.maxRPM,
                isSelected: isSelected
            )
        }
    }
}
