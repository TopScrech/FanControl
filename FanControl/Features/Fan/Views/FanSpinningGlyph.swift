import ScrechKit

struct FanSpinningGlyph: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var spinClock = FanSpinClock()

    let rpm: Double
    let isSelected: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || rpm <= 0)) { context in
            Image(systemName: "fanblades.fill")
                .title2()
                .rotationEffect(spinClock.angle(at: context.date, rpm: reduceMotion ? 0 : rpm))
        }
        .foregroundStyle(isSelected ? .white : .primary)
        .frame(width: 44, height: 44)
        .background(isSelected ? Color.accentColor : .primary.opacity(0.12), in: .circle)
        .shadow(color: isSelected ? .accentColor.opacity(0.35) : .clear, radius: 4, y: 2)
        .accessibilityHidden(true)
    }
}
