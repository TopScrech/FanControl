import SwiftUI

struct RemoteMacRowView: View {
    @Environment(RemoteControlViewModel.self) private var model
    @State private var isRenaming = false
    @State private var renameDraft = ""
    @State private var isConfirmingDeletion = false
    @State private var isShowingError = false
    @State private var deletionError = ""

    let mac: RemoteMacState
    @Binding var selection: RemoteHomeDestination?

    var body: some View {
        NavigationLink(value: RemoteHomeDestination.mac(mac.id)) {
            RemoteMacCard(mac: mac)
        }
        .disabled(model.deletingMacIDs.contains(mac.id))
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive) {
                isConfirmingDeletion = true
            }
            .labelStyle(.iconOnly)
        }
        .contextMenu {
            Button("Rename", systemImage: "pencil") {
                renameDraft = model.displayName(for: mac)
                isRenaming = true
            }

            Button("Delete", systemImage: "trash", role: .destructive) {
                isConfirmingDeletion = true
            }
        }
        .alert("Rename Mac", isPresented: $isRenaming) {
            TextField("Name", text: $renameDraft)
            Button("Cancel", role: .cancel) {}

            Button("Save") {
                model.renameMac(id: mac.id, name: renameDraft)
            }
            .disabled(renameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("This name is saved on this device")
        }
        .confirmationDialog("Delete this Mac?", isPresented: $isConfirmingDeletion, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await model.deleteMac(id: mac.id)
                        if selection == .mac(mac.id) {
                            selection = nil
                        }
                    } catch {
                        deletionError = error.localizedDescription
                        isShowingError = true
                    }
                }
            }
        } message: {
            Text("The Mac will be removed from iCloud and may reappear if remote control is still enabled on it")
        }
        .alert("Couldn’t delete Mac", isPresented: $isShowingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deletionError)
        }
    }
}
