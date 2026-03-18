import ScrechKit

struct FanActionCardView: View {
    @Bindable var model: FanVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Label("Control", systemImage: "slider.horizontal.3")
                    .headline()
                
                Spacer(minLength: 0)
                
                if model.showsControlAttemptProgress {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            
            HStack(spacing: 10) {
                if model.activeControlMode == .min {
                    Button(action: setMin) {
                        Label("Min", systemImage: "arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSetManual)
                    .keyboardShortcut("1")
                } else {
                    Button(action: setMin) {
                        Label("Min", systemImage: "arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canSetManual)
                    .keyboardShortcut("1")
                }
                
                if model.activeControlMode == .max {
                    Button(action: setMax) {
                        Label("Max", systemImage: "arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSetManual)
                    .keyboardShortcut("2")
                } else {
                    Button(action: setMax) {
                        Label("Max", systemImage: "arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canSetManual)
                    .keyboardShortcut("2")
                }
            }
            
            HStack(spacing: 10) {
                if model.activeControlMode == .auto {
                    Button(action: setAuto) {
                        Label("Auto", systemImage: "fan")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("3")
                } else {
                    Button(action: setAuto) {
                        Label("Auto", systemImage: "fan")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("3")
                }
                
                FanPresetMenuView(model: model)
                    .frame(maxWidth: .infinity)
            }
        }
        .controlSize(.large)
        .animation(.easeInOut(duration: 0.2), value: model.activeControlMode)
        .animation(.easeInOut(duration: 0.2), value: model.showsControlAttemptProgress)
        .frame(maxHeight: .infinity, alignment: .top)
        .fanCardSurface()
    }
    
    private var canSetManual: Bool {
        model.controlMinRPM != nil && model.controlMaxRPM != nil
    }
    
    private func setAuto() {
        Task {
            await model.setAuto()
        }
    }
    
    private func setMin() {
        Task {
            await model.setControlMin()
        }
    }
    
    private func setMax() {
        Task {
            await model.setControlMax()
        }
    }
}
