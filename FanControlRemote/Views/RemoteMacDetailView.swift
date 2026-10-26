import SwiftUI

struct RemoteMacDetailView: View {
    let macID: String
    @State private var showsCommandError = false
    @State private var isRenaming = false
    @State private var renameDraft = ""
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

                    RemoteTimerSectionView(mac: mac)
                }
                .alert("Command failed", isPresented: $showsCommandError) {
                    Button("OK", role: .cancel) { model.commandError = nil }
                } message: {
                    Text(model.commandError ?? "")
                }
                .navigationTitle(model.displayName(for: mac))
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    await model.refresh()
                }
            } else {
                ContentUnavailableView("Mac unavailable", systemImage: "desktopcomputer.trianglebadge.exclamationmark")
            }
        }
        .onChange(of: model.commandError) {
            showsCommandError = model.commandError != nil
        }
        .alert("Rename Mac", isPresented: $isRenaming) {
            TextField("Name", text: $renameDraft)

            Button("Cancel", role: .cancel) {}

            Button("Save") {
                model.renameMac(id: macID, name: renameDraft)
            }
            .disabled(renameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("This name is saved on this device")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Rename", systemImage: "pencil") {
                    guard let mac = model.mac(withID: macID) else { return }
                    renameDraft = model.displayName(for: mac)
                    isRenaming = true
                }
                .disabled(model.mac(withID: macID) == nil)
            }

            if model.hasPendingCommand(for: macID) {
                if #available(anyAppleOS 27.1, *) {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
                            .transition(.opacity)
                    }
                    #if os(iOS)
                    .axisBehavior(.verticalPreferred)
                    #endif
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
