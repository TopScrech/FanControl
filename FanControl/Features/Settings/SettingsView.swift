import ScrechKit
import CoreSMC

struct SettingsView: View {
    @Bindable var model: FanVM
    
    @AppStorage(AppLanguageOption.storageKey) private var preferredAppLanguageRawValue = AppLanguageManager.defaultOption.rawValue
    
    var body: some View {
        Form {
            SettingsShareSectionView()
            SettingsLanguageSectionView(preferredAppLanguageRawValue: $preferredAppLanguageRawValue)
            SettingsLaunchSectionView()
            SettingsTemperatureSectionView()
            
            SettingsUpdatesSectionView(
                appVersionDescription: model.appVersionDescription,
                isCheckingForUpdates: model.isCheckingForUpdates,
                onCheckForUpdates: checkForUpdates
            )
            
            if model.isDebugSectionVisible {
                SettingsDebugSectionView(
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
        .onAppear {
            let selectedOption = AppLanguageManager.option(from: preferredAppLanguageRawValue)
            preferredAppLanguageRawValue = selectedOption.rawValue
            AppLanguageManager.apply(option: selectedOption)
            model.setSettingsOpen(true)
        }
        .onDisappear {
            model.setSettingsOpen(false)
        }
        .alert(
            model.updatePromptTitle,
            isPresented: $model.isUpdatePromptPresented
        ) {
            Button("Not now", role: .cancel) {
                Task {
                    await model.dismissUpdatePrompt()
                }
            }
            
            Button("Update") {
                installPreparedUpdate()
            }
        } message: {
            Text(model.updatePromptMessage)
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
    
    private func checkForUpdates() {
        Task {
            await model.checkForUpdatesNow()
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
