import SwiftUI

struct RemoteHomeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(RemoteControlViewModel.self) private var model
    @State private var selection: RemoteHomeDestination?
    @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            RemoteMacList(selection: $selection)
                .toolbar {
                    if model.isDemo {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done", systemImage: "xmark") {
                                dismiss()
                            }
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gearshape") {
                            selection = .settings
                            preferredCompactColumn = .detail
                        }
                        .labelStyle(.iconOnly)
                    }
                }
        } detail: {
            NavigationStack {
                Group {
                    switch selection {
                    case .mac(let macID):
                        RemoteMacDetailView(macID: macID)
                    case .settings:
                        RemoteSettings()
                    case nil:
                        ContentUnavailableView("Select a Mac", systemImage: "desktopcomputer", description: Text("Choose a Mac to control its fans"))
                    }
                }
                .navigationDestination(for: RemoteNavigationDestination.self) {
                    switch $0 {
                    case .settings:
                        RemoteSettings()
                    }
                }
            }
            .id(selection)
        }
    }
}
