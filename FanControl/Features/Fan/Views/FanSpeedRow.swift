import ScrechKit
import CoreSMC

struct FanSpeedRow: View {
    let fan: Fan
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    FanSpinningGlyph(rpm: fan.currentRPM, isSelected: isSelected)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fan \(fan.userFacingID)")
                            .headline()

                        Text(fan.localizedModeName)
                            .caption()
                            .secondary()
                    }

                    Spacer(minLength: 0)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(fan.currentRPM.rounded(), format: .number.precision(.fractionLength(0)))
                            .title(.semibold)
                            .contentTransition(.numericText(value: fan.currentRPM))

                        Text("RPM")
                            .caption()
                            .secondary()
                    }
                    .monospacedDigit()
                }

                FanSpeedBar(
                    currentRPM: fan.currentRPM,
                    targetRPM: fan.targetRPM,
                    maxRPM: fan.maxRPM,
                    isSelected: isSelected
                )

                HStack {
                    Text(fan.minRPM.rounded(), format: .number.precision(.fractionLength(0)))

                    Spacer()

                    Text(fan.maxRPM.rounded(), format: .number.precision(.fractionLength(0)))
                }
                .caption2()
                .tertiary()
                .monospacedDigit()
            }
            .padding(12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .opacity(isSelected ? 1 : 0.42)
        .animation(.smooth(duration: 1.2), value: fan.currentRPM)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
