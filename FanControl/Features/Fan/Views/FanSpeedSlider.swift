import ScrechKit
import CoreSMC

struct FanSpeedSlider: View {
    @Environment(FanVM.self) private var model

    let fan: Fan
    let isSelected: Bool

    @State private var rpm = 0.0
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 4) {
            FanCurrentSpeedDot(
                currentRPM: fan.currentRPM,
                minRPM: fan.minRPM,
                maxRPM: fan.maxRPM,
                isSelected: isSelected
            )

            Slider(value: $rpm, in: fan.minRPM...fan.maxRPM, step: 50) {
                Text("Fan \(fan.userFacingID) speed")
            } onEditingChanged: { editing in
                isEditing = editing

                if editing {
                    model.includeFanInSelection(fan.id)
                } else {
                    apply()
                }
            }
            .labelsHidden()
            .controlSize(.small)
            .tint(isSelected ? Color.accentColor : .secondary)
            .help(Text("Drag to set a fixed fan speed"))
            .onAppear(perform: syncWithFan)
            .onChange(of: fan.targetRPM) {
                syncWithFan()
            }
        }
        .padding(.top, 6)
    }

    private func syncWithFan() {
        guard !isEditing else { return }
        rpm = min(max(fan.targetRPM, fan.minRPM), fan.maxRPM)
    }

    private func apply() {
        let rpm = rpm.rounded()
        let fanID = fan.id

        Task {
            await model.setManualRPM(rpm, fanID: fanID)
        }
    }
}
