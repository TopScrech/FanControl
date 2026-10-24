import SwiftUI

struct RemoteMacDetailView: View {
    let macID: String
    @Environment(RemoteControlViewModel.self) private var model

    var body: some View {
        Group {
            if let mac = model.mac(withID: macID) {
                List {
                    Section {
                        RemoteAllFansControlView(mac: mac)
                    }

                    Section("Fans") {
                        ForEach(mac.fans) {
                            RemoteFanControlView(fan: $0, mac: mac)
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
                if #available(anyAppleOS 27.1, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                            .transition(.opacity)
                    }
                    .axisBehavior(.verticalPreferred)
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                            .transition(.opacity)
                    }
                }
            }
        }
    }
}
