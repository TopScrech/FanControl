import SwiftUI

struct MainWindowLevelView: NSViewRepresentable {
    let keepsWindowOnTop: Bool
    
    func makeNSView(context: Context) -> MainWindowLevelHostingView {
        let view = MainWindowLevelHostingView()
        view.keepsWindowOnTop = keepsWindowOnTop
        return view
    }
    
    func updateNSView(_ nsView: MainWindowLevelHostingView, context: Context) {
        nsView.keepsWindowOnTop = keepsWindowOnTop
    }
    
    static func dismantleNSView(_ nsView: MainWindowLevelHostingView, coordinator: ()) {
        nsView.keepsWindowOnTop = false
    }
}
