import ScrechKit

struct ContentView: View {
    @Bindable var model: FanVM
    @State private var targetRPM = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let error = model.errorText {
                Text(error)
                    .foregroundStyle(.red)
                    .textSelection(.enabled)
            }
            
            if model.fans.isEmpty {
                Text("No fans detected")
                    .secondary()
            } else {
                Picker("Fan", selection: $model.selectedFanID) {
                    ForEach(model.fans) {
                        Text($0.displayName)
                            .tag($0.id)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: model.selectedFanID) {
                    syncTarget()
                }
                
                if let fan = model.selectedFan {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent("Mode", value: fan.modeName)
                            LabeledContent("Target", value: fan.targetRPM.formattedRPM)
                            LabeledContent("Min", value: fan.minRPM.formattedRPM)
                            LabeledContent("Max", value: fan.maxRPM.formattedRPM)
                        }
                        .monospacedDigit()
                    }
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 10) {
                            Slider(value: $targetRPM, in: fan.minRPM...fan.maxRPM, step: 10)
                            
                            HStack {
                                Text(targetRPM.formattedRPM)
                                    .monospacedDigit()
                                
                                Spacer()
                                
                                Button("Manual") {
                                    Task { await model.setManualRPM(targetRPM) }
                                }
                                
                                Button("Auto") {
                                    Task { await model.setAuto() }
                                }
                                
                                Button("Min") {
                                    Task { await model.setManualRPM(fan.minRPM) }
                                }
                                
                                Button("Full") {
                                    Task { await model.setManualRPM(fan.maxRPM) }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 420)
        .onAppear {
            syncTarget()
        }
        .onChange(of: model.fans) {
            syncTarget()
        }
    }
    
    private func syncTarget() {
        guard let fan = model.selectedFan else { return }
        
        let clamped = min(max(fan.targetRPM, fan.minRPM), fan.maxRPM)
        targetRPM = clamped
    }
}

private extension Double {
    var formattedRPM: String {
        "\(Int(self.rounded())) RPM"
    }
}
