import SwiftUI

struct RemoteMacDetailView: View {
    let macID: String
    @Bindable var model: RemoteControlViewModel

    var body: some View {
        Group {
            if let mac = model.mac(withID: macID) {
                List {
                    Section {
                        RemoteAllFansControlView(mac: mac, model: model)
                    }

                    Section("Fans") {
                        ForEach(mac.fans) {
                            RemoteFanControlView(fan: $0, mac: mac, model: model)
                        }
                    }
                }
                .navigationTitle(mac.name)
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    await model.refresh()
                }
            } else {
                ContentUnavailableView("Mac unavailable", systemImage: "desktopcomputer.trianglebadge.exclamationmark")
            }
        }
        .toolbar {
            if model.hasPendingCommand(for: macID) {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressView()
                        .transition(.opacity)
                }
            }
        }
    }
}
