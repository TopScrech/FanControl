import SwiftUI

@main
struct FanControlApp: App {
    @State private var model = FanVM()
    
    @AppStorage("hideWindowOnLaunch") private var hideWindowOnLaunch = false
    @AppStorage(AppLanguageOption.storageKey) private var preferredAppLanguageRawValue = AppLanguageManager.defaultOption.rawValue
    
    @State private var didApplyLaunchWindowPreference = false
    
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(
                model: model,
                showsHideWindowButton: true,
                showsUpdateAlert: true
            )
            .environment(\.locale, appLocale)
            .frame(minHeight: 450, idealHeight: 600, maxHeight: 700)
            .task {
                let selectedOption = preferredAppLanguage
                preferredAppLanguageRawValue = selectedOption.rawValue
                AppLanguageManager.apply(option: selectedOption)
                await applyLaunchWindowPreference()
            }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Check for updates", action: checkForUpdates)
                    .disabled(model.isCheckingForUpdates)
                
                Button("Show Debug Section", action: model.revealDebugSection)
                    .keyboardShortcut("d", modifiers: [.command])
            }
        }
        
        Settings {
            NavigationStack {
                SettingsView(model: model)
            }
            .environment(\.locale, appLocale)
        }
        
        MenuBarExtra("FanControl", systemImage: model.isAnyFanSpinning ? "fanblades.fill" : "fanblades") {
            ContentView(
                model: model,
                showsHideWindowButton: false,
                showsUpdateAlert: false
            )
            .environment(\.locale, appLocale)
        }
        .menuBarExtraStyle(.window)
    }
    
    private var preferredAppLanguage: AppLanguageOption {
        AppLanguageManager.option(from: preferredAppLanguageRawValue)
    }
    
    private var appLocale: Locale {
        AppLanguageManager.locale(for: preferredAppLanguage)
    }
    
    private func applyLaunchWindowPreference() async {
        guard !didApplyLaunchWindowPreference else { return }
        didApplyLaunchWindowPreference = true
        guard hideWindowOnLaunch else { return }
        
        await Task.yield()
        
        let app = NSApplication.shared
        let window = app.keyWindow ?? app.mainWindow ?? app.windows.first { $0.isVisible }
        window?.orderOut(nil)
    }
    
    private func checkForUpdates() {
        Task {
            await model.checkForUpdatesNow()
        }
    }
}
