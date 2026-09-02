import ScrechKit

struct RemoteAllFansControlView: View {
    let mac: RemoteMacState
    @Bindable var model: RemoteControlVM

    var body: some View {
        VStack(alignment: .leading) {
            Text("All fans")
                .headline()
            
            RemoteFanActionButtons(fanID: RemoteFanCommand.allFansID, mac: mac, model: model)
        }
    }
}
