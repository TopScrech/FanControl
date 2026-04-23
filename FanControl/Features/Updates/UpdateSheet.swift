import ScrechKit

struct UpdateSheet: View {
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
                        UpdateChangelogCard($0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            UpdateSheetActions(
                isUpdateDisabled: model.isCheckingForUpdates,
                onCancel: cancelUpdate,
                onInstall: installPreparedUpdate
            )
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 460)
        .background(
            UpdateSheetTouchBarBridge(
                isUpdateDisabled: model.isCheckingForUpdates,
                onCancel: cancelUpdate,
                onInstall: installPreparedUpdate
            )
        )
    }
    
    private func cancelUpdate() {
        Task {
            await model.dismissUpdatePrompt()
        }
    }
    
    private func installPreparedUpdate() {
        Task {
            await model.installPreparedUpdate()
        }
    }
}
