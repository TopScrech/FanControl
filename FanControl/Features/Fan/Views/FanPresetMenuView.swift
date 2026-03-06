import ScrechKit

struct FanPresetMenuView: View {
    let canUsePresets: Bool
    let presetRPMs: [Int]
    let activeMode: FanControlMode?
    let setPreset: (Int) -> Void
    
    @State private var showsPresetMenu = false
    @State private var showsLicenseAlert = false
    
    var body: some View {
        Group {
            if activeMode == .preset {
                Button {
                    showPresetMenuOrLicenseAlert()
                } label: {
                    Label("Presets", systemImage: "dial.low")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    showPresetMenuOrLicenseAlert()
                } label: {
                    Label("Preset", systemImage: "dial.low")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .disabled(presetRPMs.isEmpty)
        .help(
            canUsePresets
            ? String(localized: "Preset control")
            : String(localized: "Preset control requires an active license")
        )
        .popover(isPresented: $showsPresetMenu, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(presetRPMs, id: \.self) { rpm in
                            Button {
                                setPreset(rpm)
                                showsPresetMenu = false
                            } label: {
                                Text("\(rpm) RPM")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 180)
            }
            .frame(width: 180)
        }
        .alert(String(localized: "License required"), isPresented: $showsLicenseAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Activate your license in Settings to use presets")
        }
    }

    private func showPresetMenuOrLicenseAlert() {
        if canUsePresets {
            showsPresetMenu.toggle()
            return
        }

        showsLicenseAlert = true
    }
}
