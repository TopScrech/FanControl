import ScrechKit
import CoreSMC

struct SettingsView: View {
    @AppStorage("keepsWindowOnTop") private var keepsWindowOnTop = false
    
    @Bindable var model: FanVM
    
    @AppStorage(AppLanguageOption.storageKey) private var preferredAppLanguageRawValue = AppLanguageManager.defaultOption.rawValue
    
    var body: some View {
        Form {
            ShareWebsiteButton()
            SettingsLicenseSection(model: model)
            SettingsLaunchSection()
            SettingsLanguageSection(preferredAppLanguageRawValue: $preferredAppLanguageRawValue)
            SettingsTemperatureSection()
            
            SettingsUpdatesSection(model: model)
            
            if model.isDebugSectionVisible {
                SettingsDebugSection(model: model)
            }
        }
        .navigationTitle("Settings")
        .formStyle(.grouped)
        .buttonStyle(.plain)
        .frame(width: 500, height: 600)
        .background(MainWindowLevelView(keepsWindowOnTop: keepsWindowOnTop))
        .background(FanSelectionShortcutsView(changeSelectedFan: model.changeSelectedFan))
        .onAppear {
            let selectedOption = AppLanguageManager.option(from: preferredAppLanguageRawValue)
            preferredAppLanguageRawValue = selectedOption.rawValue
            AppLanguageManager.apply(option: selectedOption)
            model.setSettingsOpen(true)
        }
        .onDisappear {
            model.setSettingsOpen(false)
        }
        .sheet($model.isUpdatePromptPresented) {
            UpdateSheet(model: model)
        }
        .alert(item: $model.settingsUpdateStatusAlert) { updateStatusAlert in
            Alert(
                title: Text(updateStatusAlert.title),
                message: Text(updateStatusAlert.message),
                dismissButton: .cancel(Text("OK")) {
                    model.dismissUpdateStatusAlert(for: .settings)
                }
            )
        }
    }
    
    private func cancelUpdate() {
        Task {
            await model.dismissUpdatePrompt()
        }
    }
    
    private func installPreparedUpdate() {
        Task {
            await model.installPreparedUpdate()
        }
    }
}

#Preview {
    SettingsView(model: FanVM())
}
