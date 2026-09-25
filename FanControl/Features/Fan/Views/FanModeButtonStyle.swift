import ScrechKit

struct FanModeButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(FanModeLabelStyle(isActive: isActive, isPressed: configuration.isPressed))
    }
}
