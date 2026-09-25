import ScrechKit

struct FanSelectionChipStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .caption(.medium)
            .monospacedDigit()
            .lineLimit(1)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(.primary.opacity(isSelected ? 0.2 : 0), in: .capsule)
            .shadow(color: .black.opacity(isSelected ? 0.2 : 0), radius: 1.5, y: 1)
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
