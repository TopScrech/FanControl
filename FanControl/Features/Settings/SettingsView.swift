import ScrechKit
import CoreSMC
import LaunchAtLogin

struct SettingsView: View {
    @Bindable var model: FanVM
    
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    @AppStorage("hideWindowOnLaunch") private var hideWindowOnLaunch = false
    @AppStorage(AppLanguageOption.storageKey) private var preferredAppLanguageRawValue = AppLanguageManager.defaultOption.rawValue
    
    var body: some View {
        Form {
            Section {
                ShareWebsiteButtonView()
            }
            
            Section("Language") {
                Picker("App language", selection: $preferredAppLanguageRawValue) {
                    ForEach(AppLanguageOption.allCases) { option in
                        Text("\(option.flagEmoji) \(option.displayName)")
                            .tag(option.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: preferredAppLanguageRawValue) { _, newValue in
                    let selectedOption = AppLanguageManager.option(from: newValue)
                    AppLanguageManager.apply(option: selectedOption)
                }
            }
            
            Section("Launch") {
                LaunchAtLogin.Toggle()
                
                Toggle("Hide window on launch", isOn: $hideWindowOnLaunch)
            }
            
            Section("Temperature") {
                Picker("Measurement unit", selection: $temperatureUnitRawValue) {
                    ForEach(TemperatureUnit.allCases) {
                        Text($0.title)
                            .tag($0.rawValue)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Precision", selection: $temperaturePrecisionRawValue) {
                    ForEach(TemperaturePrecision.allCases) {
                        Text($0.title)
                            .tag($0.rawValue)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section("Updates") {
                LabeledContent("Version", value: model.appVersionDescription)
                
                Button(action: checkForUpdates) {
                    LabeledContent("Check for updates") {
                        if model.isCheckingForUpdates {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.trianglehead.clockwise")
                        }
                    }
                }
                .disabled(model.isCheckingForUpdates)
            }
            
            if model.isDebugSectionVisible {
                Section("Debug") {
                    LabeledContent("Device", value: model.processorName)
                    
                    Button(action: model.presentFakeUpdatePrompt) {
                        LabeledContent {
                            Image(systemName: "arrow.trianglehead.clockwise")
                        } label: {
                            Text("Show fake update alert")
                        }
                    }
                    
                    Button(action: copyDebugText) {
                        LabeledContent {
                            Image(systemName: "document.on.document")
                        } label: {
                            Text("Copy all sensor data")
                        }
                    }
                }
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
