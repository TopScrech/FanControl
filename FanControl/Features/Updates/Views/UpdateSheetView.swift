import ScrechKit

struct UpdateSheetView: View {
    @Bindable var model: FanVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.updatePromptTitle)
                .title2(.semibold)
            
            Text("Release notes")
                .headline()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(model.updateChangelogEntries) {
                        UpdateChangelogCardView(entry: $0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                Spacer()
                
                Button("Not now", action: cancelUpdate)
                    .keyboardShortcut(.cancelAction)
                
                Button("Update", action: installPreparedUpdate)
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.isCheckingForUpdates)
            }
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 460)
    }
    
    private func installPreparedUpdate() {
        Task {
            await model.installPreparedUpdate()
        }
    }
    
    private func cancelUpdate() {
        Task {
            await model.dismissUpdatePrompt()
        }
    }
}
