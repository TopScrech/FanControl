import SwiftUI

struct MainWindowLevelView: NSViewRepresentable {
    let keepsWindowOnTop: Bool
    let changeSelectedFan: (Int) -> Void
    
    func makeNSView(context: Context) -> MainWindowLevelHostingView {
        let view = MainWindowLevelHostingView()
        view.keepsWindowOnTop = keepsWindowOnTop
        view.changeSelectedFan = changeSelectedFan
        return view
    }
    
    func updateNSView(_ nsView: MainWindowLevelHostingView, context: Context) {
        nsView.keepsWindowOnTop = keepsWindowOnTop
        nsView.changeSelectedFan = changeSelectedFan
    }
    
    static func dismantleNSView(_ nsView: MainWindowLevelHostingView, coordinator: ()) {
        nsView.keepsWindowOnTop = false
        nsView.changeSelectedFan = nil
    }
}
