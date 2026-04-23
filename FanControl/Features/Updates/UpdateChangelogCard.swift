import ScrechKit

struct UpdateChangelogCard: View {
    private let entry: UpdateChangelogEntry
    
    init(_ entry: UpdateChangelogEntry) {
        self.entry = entry
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(entry.tagName)
                    .headline()
                
                if entry.isPrerelease {
                    Text("Pre-release")
                        .caption(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .foregroundStyle(.orange)
                        .background(.orange.opacity(0.16), in: .capsule)
                }
            }
            
            Text(entry.notes)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}
