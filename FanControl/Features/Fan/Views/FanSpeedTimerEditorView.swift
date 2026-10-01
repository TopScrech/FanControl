import ScrechKit

struct FanSpeedTimerEditorView: View {
    @Environment(FanVM.self) private var model
    @Binding var draft: FanSpeedTimerDraft
    let minimumRPM: Double
    let maximumRPM: Double

    private let rpmFormat = FloatingPointFormatStyle<Double>.number
        .grouping(.never)
        .precision(.fractionLength(0))

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    if model.showsAllFansOption {
                        Text(targetName)
                            .caption()
                    }

                    Spacer(minLength: 0)

                    TextField("RPM", value: $draft.rpm, format: rpmFormat)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .monospacedDigit()
                        .frame(maxWidth: 64)

                    Text("RPM")
                        .caption()
                        .secondary()
                }

                if minimumRPM < maximumRPM {
                    Slider(value: $draft.rpm, in: minimumRPM...maximumRPM) {
                        Text("Fan speed")
                    } minimumValueLabel: {
                        Text(minimumRPM, format: rpmFormat)
                    } maximumValueLabel: {
                        Text(maximumRPM, format: rpmFormat)
                    }
                    .labelsHidden()
                    .caption2()
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                }
            }

            FanSpeedTimerDurationView(draft: $draft)
        }
    }

    private var targetName: String {
        if model.controlsAllFans {
            String(localized: "All fans")
        } else {
            String(localized: "Fan \(model.selectedFanID + 1)")
        }
    }
}
