import ScrechKit

struct FanCurrentSpeedDot: View {
    let currentRPM: Double
    let minRPM: Double
    let maxRPM: Double
    let isSelected: Bool

    @State private var width = 0.0

    // Keeps the dot aligned with the slider thumb, which stops short of the track ends
    private let thumbInset = 5.0
    private let size = 6.0

    var body: some View {
        Circle()
            .fill(isSelected ? Color.accentColor : .secondary)
            .frame(width: size, height: size)
            .offset(x: thumbInset + (width - thumbInset * 2) * progress - size / 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: Double.self) {
                $0.size.width
            } action: {
                width = $0
            }
            .opacity(currentRPM > 0 ? 1 : 0)
            .accessibilityHidden(true)
    }

    private var progress: Double {
        guard maxRPM > minRPM else { return 0 }
        return min(max((currentRPM - minRPM) / (maxRPM - minRPM), 0), 1)
    }
}
