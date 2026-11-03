import ScrechKit

struct FanSpinningGlyph: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let rpm: Double
    let isSelected: Bool

    var body: some View {
        FanRotorView(rpm: reduceMotion ? 0 : rpm, isSelected: isSelected)
            .frame(44)
            .background(isSelected ? Color.accentColor : .primary.opacity(0.12), in: .circle)
            .shadow(color: isSelected ? .accentColor.opacity(0.35) : .clear, radius: 4, y: 2)
            .accessibilityHidden(true)
    }
}
