import ScrechKit

struct FanFixedPresetList: View {
    let presetRPMs: [Int]
    let activeRPM: Int?
    let setPreset: (Int) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Fixed presets")
                    .headline()
                
                Spacer(minLength: 0)
                
                Text("RPM")
                    .caption()
                    .secondary()
            }
            
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(presetRPMs, id: \.self) { rpm in
                    Button {
                        setPreset(rpm)
                    } label: {
                        Text(rpm, format: .number)
                    }
                    .buttonStyle(FanPresetChipStyle(isActive: rpm == activeRPM))
                    .accessibilityLabel(Double(rpm).formattedRPM)
                }
            }
        }
    }
}
