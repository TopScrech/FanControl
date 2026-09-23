import ScrechKit

struct FanActionCard: View {
    @Bindable var model: FanVM
    
    private var canSetManual: Bool {
        model.controlMinRPM != nil && model.controlMaxRPM != nil
    }
    
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
                    AsyncButton(action: model.setControlMin) {
                        Label("Min", systemImage: "arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSetManual)
                    .keyboardShortcut("1")
                } else {
                    AsyncButton(action: model.setControlMin) {
                        Label("Min", systemImage: "arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canSetManual)
                    .keyboardShortcut("1")
                }
                
                if model.activeControlMode == .max {
                    AsyncButton(action: model.setControlMax) {
                        Label("Max", systemImage: "arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSetManual)
                    .keyboardShortcut("2")
                } else {
                    AsyncButton(action: model.setControlMax) {
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
                    AsyncButton(action: model.setAuto) {
                        Label("Auto", systemImage: "fan")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("3")
                } else {
                    AsyncButton(action: model.setAuto) {
                        Label("Auto", systemImage: "fan")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("3")
                }
                
                FanPresetMenu(model: model)
                    .frame(maxWidth: .infinity)
            }
        }
        .controlSize(.large)
        .animation(.easeInOut(duration: 0.2), value: model.activeControlMode)
        .animation(.easeInOut(duration: 0.2), value: model.showsControlAttemptProgress)
        .frame(maxHeight: .infinity, alignment: .top)
        .fanCardSurface()
    }
}
