import ScrechKit

struct FanFixedPresetList: View {
    let presetRPMs: [Int]
    let setPreset: (Int) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fixed presets")
                .headline()
            
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(presetRPMs, id: \.self) { rpm in
                        Button(Double(rpm).formattedRPM) {
                            setPreset(rpm)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: 160)
        }
    }
}
