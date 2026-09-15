import SwiftUI

struct RemoteSettingsView: View {
    var body: some View {
        Form {
            Section {
                NavigationLink(value: RemoteNavigationDestination.demo) {
                    Label("Demo", systemImage: "play.rectangle")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
