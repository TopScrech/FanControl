import SwiftUI

struct ContentViewBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.12), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            LinearGradient(
                colors: [.clear, .black.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

#Preview {
    ContentViewBackground()
}
