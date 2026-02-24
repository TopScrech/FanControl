import ScrechKit

struct FanEmptyStateView: View {
    var body: some View {
        ContentUnavailableView("No fans detected", systemImage: "fanblades")
            .frame(maxWidth: .infinity, minHeight: 180)
            .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}
