import ScrechKit

struct FanModeLabelContent<Icon: View, Title: View>: View {
    @Environment(\.isEnabled) private var isEnabled

    let icon: Icon
    let title: Title
    let isActive: Bool
    let isPressed: Bool

    var body: some View {
        VStack(spacing: 6) {
            icon
                .title3(.semibold)
                .foregroundStyle(isActive ? .white : .primary)
                .frame(width: 50, height: 50)
                .background(isActive ? Color.accentColor : .primary.opacity(isPressed ? 0.19 : 0.13), in: .circle)
                .shadow(color: isActive ? .accentColor.opacity(0.45) : .clear, radius: 6, y: 3)
                .scaleEffect(isPressed ? 0.94 : 1)

            title
                .caption(.medium)
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .opacity(isEnabled ? 1 : 0.4)
        .animation(.easeOut(duration: 0.15), value: isPressed)
    }
}
