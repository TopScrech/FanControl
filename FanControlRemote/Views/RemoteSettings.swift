import SwiftUI
import Appearance

struct RemoteSettings: View {
    @AppStorage("appearance") private var appearance: Appearance = .system

    var body: some View {
        Form {
            AppearancePicker($appearance)

            Section {
                NavigationLink(value: RemoteNavigationDestination.demo) {
                    Label("Demo", systemImage: "play.rectangle")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
