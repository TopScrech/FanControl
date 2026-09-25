import ScrechKit

struct FanCardSurface: ViewModifier {
    let padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.fill.tertiary, in: .rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
            }
    }
}

extension View {
    func fanCardSurface(padding: CGFloat = 14) -> some View {
        modifier(FanCardSurface(padding: padding))
    }
}
