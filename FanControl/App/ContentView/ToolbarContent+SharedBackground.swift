import SwiftUI

extension ToolbarContent {
    @ToolbarContentBuilder
    func hidesSharedToolbarBackground() -> some ToolbarContent {
        if #available(macOS 26, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
