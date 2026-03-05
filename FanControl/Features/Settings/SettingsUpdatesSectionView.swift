import ScrechKit

struct SettingsUpdatesSectionView: View {
    let appVersionDescription: String
    let isCheckingForUpdates: Bool
    let onCheckForUpdates: () -> Void

    var body: some View {
        Section("Updates") {
            LabeledContent("Version", value: appVersionDescription)

            Button(action: onCheckForUpdates) {
                LabeledContent("Check for updates") {
                    if isCheckingForUpdates {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.trianglehead.clockwise")
                    }
                }
            }
            .disabled(isCheckingForUpdates)
        }
    }
}
