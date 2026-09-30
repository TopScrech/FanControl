import ScrechKit

struct FanSpeedTimerDurationView: View {
    @Binding var draft: FanSpeedTimerDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Duration")
                    .subheadline(.medium)

                Spacer(minLength: 0)

                TimelineView(.everyMinute) { context in
                    Text("Until \(context.date.addingTimeInterval(draft.duration), format: .dateTime.hour().minute())")
                        .caption()
                        .monospacedDigit()
                        .secondary()
                }
            }

            HStack {
                Picker("Hours", selection: $draft.hours) {
                    ForEach(0..<24, id: \.self) {
                        Text("\($0) h")
                            .tag($0)
                    }
                }

                Picker("Minutes", selection: $draft.minutes) {
                    ForEach(0..<60, id: \.self) {
                        Text("\($0) min")
                            .tag($0)
                    }
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .monospacedDigit()
        }
    }
}
