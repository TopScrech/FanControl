import ScrechKit

struct FanSpeedProgressView: View {
    let currentRPM: Double
    let minRPM: Double
    let maxRPM: Double
    let isSelected: Bool

    var body: some View {
        ProgressView(value: progress)
            .progressViewStyle(.linear)
            .tint(isSelected ? Color.accentColor : .secondary)
            .accessibilityHidden(true)
    }

    private var progress: Double {
        guard maxRPM > minRPM else { return 0 }
        return min(max((currentRPM - minRPM) / (maxRPM - minRPM), 0), 1)
    }
}
