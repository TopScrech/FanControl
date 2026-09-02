import ScrechKit

struct RemoteFanControlView: View {
    let fan: RemoteFanState
    let mac: RemoteMacState
    @Bindable var model: RemoteControlViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Fan \(fan.id + 1)")
                    .headline()
                
                Spacer()
                
                Text(fan.currentRPM, format: .number.precision(.fractionLength(0)))
                    .monospacedDigit()
                
                Text("RPM")
                    .secondary()
            }
            
            Text("Range \(fan.minRPM.formatted(.number.precision(.fractionLength(0))))–\(fan.maxRPM.formatted(.number.precision(.fractionLength(0)))) RPM")
                .secondary()
            
            RemoteFanActionButtons(fanID: fan.id, mac: mac, model: model)
        }
    }
}
