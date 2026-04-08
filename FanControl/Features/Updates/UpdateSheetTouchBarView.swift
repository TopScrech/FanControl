import SwiftUI

@MainActor
final class UpdateSheetTouchBarView: NSView, NSTouchBarDelegate {
    static let cancelItemIdentifier = NSTouchBarItem.Identifier("dev.topscrech.FanControl.update.cancel")
    static let installItemIdentifier = NSTouchBarItem.Identifier("dev.topscrech.FanControl.update.install")
    static let customizationIdentifier = NSTouchBar.CustomizationIdentifier("dev.topscrech.FanControl.update")
    
    var onCancel: () -> Void = {}
    var onInstall: () -> Void = {}
    
    var isUpdateDisabled = false {
        didSet {
            updateTouchBarItems()
        }
    }
    
    private weak var attachedWindow: NSWindow?
    private weak var cancelButton: NSButton?
    private weak var installButton: NSButton?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if let attachedWindow, attachedWindow.touchBar === touchBar {
            attachedWindow.touchBar = nil
        }
        
        attachedWindow = window
        installTouchBarIfNeeded()
    }
    
    func installTouchBarIfNeeded() {
        guard let window else { return }
        
        if touchBar == nil {
            touchBar = makeTouchBar()
        }
        
        window.touchBar = touchBar
        updateTouchBarItems()
    }
    
    func removeTouchBar() {
        if let attachedWindow, attachedWindow.touchBar === touchBar {
            attachedWindow.touchBar = nil
        }
        
        attachedWindow = nil
        touchBar = nil
    }
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.customizationIdentifier = Self.customizationIdentifier
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [
            .flexibleSpace,
            Self.cancelItemIdentifier,
            Self.installItemIdentifier,
        ]
        touchBar.principalItemIdentifier = Self.installItemIdentifier
        return touchBar
    }
    
    func touchBar(
        _ touchBar: NSTouchBar,
        makeItemForIdentifier identifier: NSTouchBarItem.Identifier
    ) -> NSTouchBarItem? {
        switch identifier {
        case Self.cancelItemIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: String(localized: "Not now"), target: self, action: #selector(cancelUpdate))
            item.view = button
            cancelButton = button
            return item
            
        case Self.installItemIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: String(localized: "Update"), target: self, action: #selector(installUpdate))
            button.bezelColor = .controlAccentColor
            button.isEnabled = !isUpdateDisabled
            item.view = button
            installButton = button
            return item
            
        default:
            return nil
        }
    }
    
    private func updateTouchBarItems() {
        cancelButton?.isEnabled = true
        installButton?.isEnabled = !isUpdateDisabled
    }
    
    @objc private func cancelUpdate() {
        onCancel()
    }
    
    @objc private func installUpdate() {
        onInstall()
    }
}
