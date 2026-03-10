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
                SettingsDebugSection(
                    processorName: model.processorName,
                    onPresentFakeUpdatePrompt: model.presentFakeUpdatePrompt,
                    onCopyDebugText: copyDebugText
                )
            }
        }
        .navigationTitle("Settings")
        .formStyle(.grouped)
        .buttonStyle(.plain)
        .frame(width: 500, height: 600)
        .background(MainWindowLevelView(keepsWindowOnTop: keepsWindowOnTop))
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
    
    private func copyDebugText() {
        let sensorLines = model.temperatureSensors.map {
            "\($0.key): \($0.celsius.formatted(.number.precision(.fractionLength(1))))"
        }
        
        let text = ([model.processorName, ""] + sensorLines).joined(separator: "\n")
#if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
#endif
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
