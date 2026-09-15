import SwiftUI

struct UpdateSheetTouchBarBridge: NSViewRepresentable {
    let isUpdateDisabled: Bool
    let onCancel: () -> Void
    let onInstall: () -> Void
    
    func makeNSView(context: Context) -> UpdateSheetTouchBarView {
        let view = UpdateSheetTouchBarView()
        view.onCancel = onCancel
        view.onInstall = onInstall
        view.isUpdateDisabled = isUpdateDisabled
        
        return view
    }
    
    func updateNSView(_ nsView: UpdateSheetTouchBarView, context: Context) {
        nsView.onCancel = onCancel
        nsView.onInstall = onInstall
        nsView.isUpdateDisabled = isUpdateDisabled
        nsView.installTouchBarIfNeeded()
    }
    
    static func dismantleNSView(_ nsView: UpdateSheetTouchBarView, coordinator: ()) {
        nsView.removeTouchBar()
    }
}
