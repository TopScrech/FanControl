import SwiftUI

struct RemoteMacList: View {
    @Bindable var model: RemoteControlViewModel
    
    var body: some View {
        Group {
            if model.macs.isEmpty {
                ContentUnavailableView {
                    Label("Looking for a Mac", systemImage: "desktopcomputer")
                } description: {
                    Text("Keep FanControl running with remote control enabled on your Mac")
                } actions: {
                    ProgressView()
                }
            } else {
                List(model.macs) { mac in
                    NavigationLink(value: mac.id) {
                        RemoteMacCard(mac: mac)
                    }
                }
            }
        }
        .navigationTitle("FanControl")
        .navigationDestination(for: String.self) {
            RemoteMacDetailView(macID: $0, model: model)
        }
        .refreshable {
            await model.refresh()
        }
    }
}
