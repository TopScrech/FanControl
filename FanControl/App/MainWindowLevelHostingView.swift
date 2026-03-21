import SwiftUI

final class MainWindowLevelHostingView: NSView {
    var keepsWindowOnTop = false {
        didSet {
            applyWindowLevel()
        }
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyWindowLevel()
    }
    
    private func applyWindowLevel() {
        guard let window else { return }
        window.level = keepsWindowOnTop ? .floating : .normal
    }
}
