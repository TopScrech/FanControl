import ScrechKit

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    
    @Bindable var model: FanVM
    let showsHideWindowButton: Bool
    let showsUpdateAlert: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("FanControl")
                    .title3(.semibold)
                
                Spacer(minLength: 0)
                
                if showsHideWindowButton {
                    Button("Hide window", systemImage: "eye.slash", action: hideWindow)
                } else {
                    Button("Show window", systemImage: "macwindow", action: showWindow)
                }
            }
            .controlSize(.small)
            
            if let error = model.errorText {
                FanErrorBannerView(error: error, onDismiss: model.dismissError)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.96).combined(with: .opacity)
                        )
                    )
            }
            
            FanControlsView(model: model)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .frame(width: 350)
        .background {
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.12), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                LinearGradient(
                    colors: [.clear, .black.opacity(0.06)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .animation(.smooth(duration: 0.25), value: model.errorText)
        .sheet(
            isPresented: showsUpdateAlert && !model.isSettingsOpen ? $model.isUpdatePromptPresented : .constant(false)
        ) {
            UpdateSheetView(
                title: model.updatePromptTitle,
                summary: model.updatePromptSummary,
                changelogEntries: model.updateChangelogEntries,
                isInstalling: model.isCheckingForUpdates,
                onNotNow: cancelUpdate,
                onUpdate: installPreparedUpdate
            )
        }
    }
    
    private func installPreparedUpdate() {
        Task {
            await model.installPreparedUpdate()
        }
    }
    
    private func cancelUpdate() {
        Task {
            await model.dismissUpdatePrompt()
        }
    }
    
    private func showWindow() {
        let menuBarWindow = NSApplication.shared.keyWindow
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
        menuBarWindow?.orderOut(nil)
    }
    
    private func hideWindow() {
        NSApplication.shared.keyWindow?.orderOut(nil)
    }
    
}
