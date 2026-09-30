import SwiftUI

struct WindowToolbarBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .scrollEdgeEffectStyle(.hard, for: .top)
        } else {
            content
        }
    }
}

extension View {
    func windowToolbarBackground() -> some View {
        modifier(WindowToolbarBackground())
    }
}
