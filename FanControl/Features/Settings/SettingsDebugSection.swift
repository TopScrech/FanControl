import ScrechKit

struct SettingsDebugSection: View {
    @Bindable var model: FanVM
    
    var body: some View {
        Section("Debug") {
            LabeledContent("Device", value: model.deviceName)
            
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
    
    private func copyDebugText() {
        let sensorLines = model.temperatureSensors.map {
            "\($0.key): \($0.celsius.formatted(.number.precision(.fractionLength(1))))"
        }
        
        let text = ([model.deviceName, ""] + sensorLines).joined(separator: "\n")
        Pasteboard.copy(text)
    }
}
