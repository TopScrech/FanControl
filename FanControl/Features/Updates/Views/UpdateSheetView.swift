import ScrechKit

struct UpdateSheetView: View {
    let title: String
    let summary: String
    let changelogEntries: [UpdateChangelogEntry]
    let isInstalling: Bool
    let onNotNow: () -> Void
    let onUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .title2(.semibold)
            
            Text(summary)
                .foregroundStyle(.secondary)
            
            Text("Release notes")
                .headline()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(changelogEntries) {
                        UpdateChangelogCardView(entry: $0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                Spacer()
                
                Button("Not now", action: onNotNow)
                    .keyboardShortcut(.cancelAction)
                
                Button("Update", action: onUpdate)
                    .keyboardShortcut(.defaultAction)
                    .disabled(isInstalling)
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 460)
    }
}
