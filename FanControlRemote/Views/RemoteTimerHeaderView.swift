import ScrechKit

struct RemoteTimerHeaderView: View {
    let endDate: Date?

    var body: some View {
        HStack {
            Text("Timer")

            Spacer()

            if let endDate {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    if endDate > context.date {
                        Text(timerInterval: context.date...endDate, countsDown: true)
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                            .fixedSize()
                    } else {
                        Text("Waiting for Mac to return to Auto")
                            .multilineTextAlignment(.trailing)
                            .secondary()
                    }
                }
            }
        }
    }
}
