import SwiftUI

struct RemoteMacList: View {
    @AppStorage("hasEnabledRemoteControl") private var hasEnabledRemoteControl = false

    @Environment(RemoteControlViewModel.self) private var model
    
    @Binding var selection: RemoteHomeDestination?

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
                List(selection: $selection) {
                    ForEach(model.macs) { mac in
                        RemoteMacRowView(mac: mac, selection: $selection)
                    }
                }
            }
        }
        .navigationTitle("FanControl")
        .toolbar {
            if !model.isDemo {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Show Setup", systemImage: "questionmark.circle") {
                        hasEnabledRemoteControl = false
                    }
                    .labelStyle(.iconOnly)
                }
            }
        }
        .refreshable {
            await model.refresh()
        }
    }
}
