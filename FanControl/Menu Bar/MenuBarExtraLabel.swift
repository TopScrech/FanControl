import SwiftUI

struct MenuBarExtraLabel: View {
    private static let speedLabelWidth = 50.0
    
    @AppStorage(FanVM.showsMenuBarFanSpeedDefaultsKey) private var showsMenuBarFanSpeed = false
    
    @Bindable var model: FanVM
    
    var body: some View {
        if let renderedLabelImage {
            Image(nsImage: renderedLabelImage)
                .renderingMode(.template)
        } else {
            Image(systemName: systemImage)
        }
    }
    
    private var systemImage: String {
        model.isAnyFanSpinning ? "fanblades.fill" : "fanblades"
    }
    
    private var renderedLabelImage: NSImage? {
        guard showsMenuBarFanSpeed, !model.menuBarCurrentSpeeds.isEmpty else { return nil }
        
        let renderer = ImageRenderer(
            content: MenuBarRenderedLabel(
                systemImage: systemImage,
                speeds: model.menuBarCurrentSpeeds,
                width: Self.speedLabelWidth
            )
        )
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        
        guard let image = renderer.nsImage else { return nil }
        
        image.isTemplate = true
        return image
    }
}
