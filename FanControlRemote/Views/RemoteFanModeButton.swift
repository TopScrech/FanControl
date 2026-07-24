import SwiftUI

struct RemoteFanModeButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let isSelected: Bool
    let action: @MainActor () -> Void

    init(
        _ title: LocalizedStringKey,
        systemImage: String,
        isSelected: Bool,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        ZStack {
            Button(title, systemImage: systemImage, action: action)
                .buttonStyle(.bordered)
                .opacity(isSelected ? 0 : 1)
                .allowsHitTesting(!isSelected)
                .accessibilityHidden(isSelected)

            Button(title, systemImage: systemImage, action: action)
                .buttonStyle(.borderedProminent)
                .opacity(isSelected ? 1 : 0)
                .allowsHitTesting(isSelected)
                .accessibilityHidden(!isSelected)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
