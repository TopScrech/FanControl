import ScrechKit

struct SettingsLanguageSectionView: View {
    @Binding var preferredAppLanguageRawValue: String

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
