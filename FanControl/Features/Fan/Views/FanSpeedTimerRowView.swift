import ScrechKit

struct FanSpeedTimerRowView: View {
    @Environment(FanVM.self) private var model
    let speedTimer: FanSpeedTimer

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let hasEnded = speedTimer.hasEnded(at: context.date)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(speedTimer.name)
                            .subheadline(.medium)

                        HStack(spacing: 4) {
                            if let rpmRange = speedTimer.rpmRange {
                                FanSpeedTimerRPMText(rpmRange: rpmRange)
                            }

                            Text("·")

                            Text("Until \(speedTimer.endDate, format: .dateTime.hour().minute())")
                        }
                        .caption()
                        .monospacedDigit()
                        .secondary()
                    }

                    Spacer(minLength: 0)

                    if hasEnded {
                        Text("Returning to Auto")
                            .caption()
                            .secondary()
                    } else {
                        Text(timerInterval: context.date...speedTimer.endDate, countsDown: true)
                            .title3(.semibold, design: .rounded)
                            .monospacedDigit()
                    }

                    AsyncButton("Cancel timer", systemImage: "xmark.circle.fill") {
                        await model.cancelFanSpeedTimer()
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Cancel timer and return to Auto")
                    .disabled(hasEnded)
                }

                ProgressView(value: speedTimer.remainingFraction(at: context.date))
                    .progressViewStyle(.linear)
                    .controlSize(.small)
                    .tint(hasEnded ? .secondary : .accentColor)
                    .animation(.linear(duration: 1), value: context.date)
            }
        }
    }
}
