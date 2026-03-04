import ScrechKit

struct FanPresetMenuView: View {
    let presetRPMs: [Int]
    let activeMode: FanControlMode?
    let setPreset: (Int) -> Void
    
    @State private var showsPresetMenu = false
    
    var body: some View {
        Group {
            if activeMode == .preset {
                Button {
                    showsPresetMenu.toggle()
                } label: {
                    Label("Presets", systemImage: "dial.low")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    showsPresetMenu.toggle()
                } label: {
                    Label("Preset", systemImage: "dial.low")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .disabled(presetRPMs.isEmpty)
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
    }
}
