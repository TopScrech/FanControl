import SwiftUI

struct RemoteTimerEditorView: View {
    @Binding var draft: FanSpeedTimerDraft
    @ScaledMetric private var durationFieldWidth = 32
    let rpmRange: ClosedRange<Double>

    var body: some View {
        LabeledContent("RPM") {
            TextField("", value: $draft.rpm, format: .number.grouping(.never).precision(.fractionLength(0)))
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .accessibilityLabel("RPM")
        }

        if rpmRange.lowerBound < rpmRange.upperBound {
            Slider(value: $draft.rpm, in: rpmRange, step: 100) {
                Text("Fan speed")
            }
        }

        LabeledContent("Duration") {
            HStack(spacing: 6) {
                TextField("", value: $draft.hours, format: .number.grouping(.never))
                    .frame(width: durationFieldWidth)
                    .accessibilityLabel("Hours")

                Text("h")
                    .foregroundStyle(.secondary)

                TextField("", value: $draft.minutes, format: .number.grouping(.never))
                    .frame(width: durationFieldWidth)
                    .accessibilityLabel("Minutes")

                Text("min")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
        }
    }
}
