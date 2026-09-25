import ScrechKit

struct FanActionCard: View {
    @Bindable var model: FanVM

    private var canSetManual: Bool {
        model.controlMinRPM != nil && model.controlMaxRPM != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("Control")
                    .headline()

                Spacer(minLength: 0)

                if model.showsControlAttemptProgress {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
            .frame(height: 16)

            HStack(alignment: .top) {
                AsyncButton("Auto", systemImage: "gauge.with.dots.needle.33percent", action: model.setAuto)
                    .buttonStyle(FanModeButtonStyle(isActive: model.activeControlMode == .auto))
                    .keyboardShortcut("3")

                FanPresetMenu(model: model)

                AsyncButton("Min", systemImage: "arrow.down", action: model.setControlMin)
                    .buttonStyle(FanModeButtonStyle(isActive: model.activeControlMode == .min))
                    .disabled(!canSetManual)
                    .keyboardShortcut("1")

                AsyncButton("Max", systemImage: "arrow.up", action: model.setControlMax)
                    .buttonStyle(FanModeButtonStyle(isActive: model.activeControlMode == .max))
                    .disabled(!canSetManual)
                    .keyboardShortcut("2")
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.activeControlMode)
        .animation(.easeInOut(duration: 0.2), value: model.showsControlAttemptProgress)
        .fanCardSurface()
    }
}
