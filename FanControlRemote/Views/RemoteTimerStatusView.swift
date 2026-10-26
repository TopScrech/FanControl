import ScrechKit

struct RemoteTimerStatusView: View {
    let fan: RemoteFanState

    var body: some View {
        HStack {
            Text("Fan \(fan.id + 1)")

            Spacer()

            if let rpm = fan.timerRPM {
                Text("\(rpm, format: .number.precision(.fractionLength(0))) RPM")
            }
        }
    }
}
