import SwiftUI

@main
struct FanControlApp: App {
    
    @NSApplicationDelegateAdaptor(AppTerminationDelegate.self) private var appTerminationDelegate
    @State private var model = FanVM()
    
    @AppStorage("hideWindowOnLaunch") private var hideWindowOnLaunch = false
    @AppStorage(FanVM.showsMenuBarAverageTemperaturesDefaultsKey) private var showsMenuBarAverageTemperatures = true
    @AppStorage(AppLanguageOption.storageKey) private var preferredAppLanguageRawValue = AppLanguageManager.defaultOption.rawValue
    
    @State private var didApplyLaunchWindowPreference = false
    
    init() {
        // Launch at login is opt-in through Settings
        // Component installation is handled by its external installer
        // No external executables are installed by the sandboxed app
    }
    
    var body: some Scene {
        mainWindowScene
        settingsScene
        primaryMenuBarExtraScene
        averageTemperatureMenuBarExtraScene
    }
    
    private var mainWindowScene: some Scene {
        WindowGroup(id: "main") {
            ContentView(model: model, showsUpdateAlert: true)
                .environment(\.locale, appLocale)
                .frame(minHeight: 460, idealHeight: 460, maxHeight: 600)
                .task {
                    configureTerminationDelegate()
                    // Hardware access is provided by the external component
                    
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
                // Direct-distribution updates are disabled in the sandboxed app
                
                Button("Show Debug Section", action: model.revealDebugSection)
                    .keyboardShortcut("d", modifiers: [.command])
            }
        }
    }
    
    private var settingsScene: some Scene {
        Settings {
            NavigationStack {
                SettingsView(model: model)
            }
            .environment(\.locale, appLocale)
        }
    }
    
    private var primaryMenuBarExtraScene: some Scene {
        MenuBarExtra {
            menuBarContentView
        } label: {
            MenuBarExtraLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
    
    private var averageTemperatureMenuBarExtraScene: some Scene {
        MenuBarExtra(isInserted: $showsMenuBarAverageTemperatures) {
            menuBarContentView
        } label: {
            MenuBarTemperatureExtraLabel(sensors: model.temperatureSensors)
        }
        .menuBarExtraStyle(.window)
    }
    
    private var menuBarContentView: some View {
        MenuBarContentView(model: model, showsUpdateAlert: false)
            .environment(\.locale, appLocale)
            .task {
                configureTerminationDelegate()
                // Hardware access is provided by the external component
            }
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
    

    

    
    private func configureTerminationDelegate() {
        appTerminationDelegate.onTerminate = {
            await model.prepareForTermination()
        }
        appTerminationDelegate.onSleep = {
            guard UserDefaults.standard.bool(forKey: FanVM.disablesFanControlOnSleepDefaultsKey) else { return }
            await model.prepareForSleep()
        }
    }
    

}
