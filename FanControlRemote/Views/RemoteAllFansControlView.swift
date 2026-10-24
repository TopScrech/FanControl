import ScrechKit

struct RemoteAllFansControlView: View {
    let mac: RemoteMacState
    @Environment(RemoteControlViewModel.self) private var model

    var body: some View {
        VStack(alignment: .leading) {
            Text("All fans")
                .headline()
            
            RemoteFanActionButtons(fanID: RemoteFanCommand.allFansID, mac: mac)
        }
    }
}
