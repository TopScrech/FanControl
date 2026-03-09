import ScrechKit

struct LicenseInactiveBadge: View {
    @Environment(\.openSettings) private var openSettings
    
    var body: some View {
        Button("License inactive", action: openAppSettings)
            .caption()
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.orange)
            .background(.orange.opacity(0.16), in: .capsule)
            .buttonStyle(.plain)
    }
    
    private func openAppSettings() {
        openSettings()
    }
}

#Preview {
    LicenseInactiveBadge()
}
