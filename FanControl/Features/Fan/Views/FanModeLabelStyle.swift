import ScrechKit

struct FanModeLabelStyle: LabelStyle {
    let isActive: Bool
    let isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        FanModeLabelContent(
            icon: configuration.icon,
            title: configuration.title,
            isActive: isActive,
            isPressed: isPressed
        )
    }
}
