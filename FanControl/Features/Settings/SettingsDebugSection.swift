import ScrechKit

struct SettingsDebugSection: View {
    let processorName: String
    let onPresentFakeUpdatePrompt: () -> Void
    let onCopyDebugText: () -> Void

    var body: some View {
        Section("Debug") {
            LabeledContent("Device", value: processorName)

            Button(action: onPresentFakeUpdatePrompt) {
                LabeledContent {
                    Image(systemName: "arrow.trianglehead.clockwise")
                } label: {
                    Text("Show fake update alert")
                }
            }

            Button(action: onCopyDebugText) {
                LabeledContent {
                    Image(systemName: "document.on.document")
                } label: {
                    Text("Copy all sensor data")
                }
            }
        }
    }
}
