import SwiftUI

extension ToolbarContent {
    // The chips draw their own capsule, so skip the Liquid Glass platter on macOS 26
    @ToolbarContentBuilder
    func hidesSharedToolbarBackground() -> some ToolbarContent {
        if #available(macOS 26, *) {
            sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}
