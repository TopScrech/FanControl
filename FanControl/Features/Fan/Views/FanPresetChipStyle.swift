import ScrechKit

struct FanPresetChipStyle: ButtonStyle {
    let isActive: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .callout(.medium)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(isActive ? .white : .primary)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(isActive ? Color.accentColor : .primary.opacity(configuration.isPressed ? 0.18 : 0.09), in: .capsule)
            .contentShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
