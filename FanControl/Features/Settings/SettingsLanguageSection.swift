import ScrechKit

struct SettingsLanguageSection: View {
    @Binding private var preferredAppLanguageRawValue: String
    
    init(_ preferredAppLanguageRawValue: Binding<String>) {
        _preferredAppLanguageRawValue = preferredAppLanguageRawValue
    }
    
    var body: some View {
        Section("Language") {
            Picker("App language", selection: $preferredAppLanguageRawValue) {
                ForEach(AppLanguageOption.allCases) {
                    Text("\($0.flagEmoji) \($0.displayName)")
                        .tag($0.rawValue)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: preferredAppLanguageRawValue) { _, newValue in
                let selectedOption = AppLanguageManager.option(from: newValue)
                AppLanguageManager.apply(option: selectedOption)
            }
        }
    }
}
