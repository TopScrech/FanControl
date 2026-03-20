import ScrechKit

struct FanSelectionShortcutsView: View {
    let changeSelectedFan: (Int) -> Void
    
    var body: some View {
        VStack {
            Button("Previous Fan", systemImage: "chevron.left") {
                changeSelectedFan(-1)
            }
            .keyboardShortcut(.leftArrow, modifiers: [.option])
            
            Button("Next Fan", systemImage: "chevron.right") {
                changeSelectedFan(1)
            }
            .keyboardShortcut(.rightArrow, modifiers: [.option])
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
