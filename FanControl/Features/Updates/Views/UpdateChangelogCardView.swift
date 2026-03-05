import ScrechKit

struct UpdateChangelogCardView: View {
    let entry: UpdateChangelogEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.tagName)
                .font(.headline)
            
            Text(entry.notes)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(12)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}
