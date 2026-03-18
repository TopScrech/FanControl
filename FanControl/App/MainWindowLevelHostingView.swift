import SwiftUI

final class MainWindowLevelHostingView: NSView {
    var keepsWindowOnTop = false {
        didSet {
            applyWindowLevel()
        }
    }

    var changeSelectedFan: ((Int) -> Void)?
    private var keyEventMonitor: Any?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyWindowLevel()
        updateKeyEventMonitor()
    }
    
    deinit {
        removeKeyEventMonitor()
    }
    
    private func applyWindowLevel() {
        guard let window else { return }
        window.level = keepsWindowOnTop ? .floating : .normal
    }

    private func updateKeyEventMonitor() {
        guard window != nil else {
            removeKeyEventMonitor()
            return
        }
        
        guard keyEventMonitor == nil else { return }
        
        keyEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyDown(event) ?? event
        }
    }

    private func removeKeyEventMonitor() {
        guard let keyEventMonitor else { return }
        NSEvent.removeMonitor(keyEventMonitor)
        self.keyEventMonitor = nil
    }

    private func handleKeyDown(_ event: NSEvent) -> NSEvent? {
        guard let window, event.window === window else { return event }
        guard !isEditingText else { return event }
        
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers.contains(.option) else { return event }
        guard !modifiers.contains(.command) else { return event }
        guard !modifiers.contains(.control) else { return event }
        
        switch event.keyCode {
        case 123:
            changeSelectedFan?(-1)
            return nil
        case 124:
            changeSelectedFan?(1)
            return nil
        default:
            return event
        }
    }

    private var isEditingText: Bool {
        guard let textView = window?.firstResponder as? NSTextView else { return false }
        return textView.isEditable
    }
}
