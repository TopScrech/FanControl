import SwiftUI

struct FanRotorView: NSViewRepresentable {
    let rpm: Double
    let isSelected: Bool

    func makeNSView(context: Context) -> FanRotorHostingView {
        FanRotorHostingView()
    }

    func updateNSView(_ nsView: FanRotorHostingView, context: Context) {
        nsView.update(rpm: rpm, isSelected: isSelected)
    }

    static func dismantleNSView(_ nsView: FanRotorHostingView, coordinator: ()) {
        nsView.stop()
    }
}
