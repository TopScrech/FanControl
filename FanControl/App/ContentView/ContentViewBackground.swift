import SwiftUI

struct ContentViewBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.06)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    ContentViewBackground()
}
