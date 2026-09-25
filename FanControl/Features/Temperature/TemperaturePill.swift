import ScrechKit

struct TemperaturePill: View {
    let value: String
    let celsius: Double?

    private var tint: Color {
        celsius?.temperatureTint ?? .secondary
    }

    var body: some View {
        Text(value)
            .footnote(.semibold)
            .monospacedDigit()
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .frame(minWidth: 58)
            .background(tint.opacity(0.16), in: .capsule)
            .animation(.easeInOut(duration: 0.6), value: celsius)
    }
}
