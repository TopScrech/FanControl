import SwiftUI

struct TransparentWindowToolbar: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15, *) {
            content
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        } else {
            content
        }
    }
}

extension View {
    func transparentWindowToolbar() -> some View {
        modifier(TransparentWindowToolbar())
    }
}
