import ScrechKit

struct FanEmptyState: View {
    var body: some View {
        ContentUnavailableView(
            "No fans detected",
            systemImage: "fanblades",
            description: Text("Fan data appears after hardware sensors are reachable")
        )
        .frame(maxWidth: .infinity, minHeight: 220)
        .fanCardSurface()
    }
}
