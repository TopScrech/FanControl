import SwiftUI

struct DemoMacListView: View {
    @State private var model = RemoteControlViewModel.demo()

    var body: some View {
        List(model.macs) { mac in
            NavigationLink(value: DemoMacDestination(macID: mac.id)) {
                RemoteMacCard(mac: mac)
            }
        }
        .navigationTitle("Demo")
        .navigationDestination(for: DemoMacDestination.self) {
            RemoteMacDetailView(macID: $0.macID, model: model)
        }
    }
}
