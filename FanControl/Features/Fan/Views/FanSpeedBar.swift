import ScrechKit

struct FanSpeedBar: View {
    let currentRPM: Double
    let targetRPM: Double
    let maxRPM: Double
    let isSelected: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)

                Capsule()
                    .fill(isSelected ? Color.accentColor : .primary.opacity(0.75))
                    .frame(width: geometry.size.width * fraction(currentRPM))

                Capsule()
                    .fill(.primary.opacity(0.55))
                    .frame(width: 2, height: 10)
                    .offset(x: geometry.size.width * fraction(targetRPM) - 1)
                    .animation(.smooth(duration: 0.5), value: targetRPM)
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }

    private func fraction(_ rpm: Double) -> Double {
        guard maxRPM > 0 else { return 0 }
        return min(max(rpm / maxRPM, 0), 1)
    }
}
