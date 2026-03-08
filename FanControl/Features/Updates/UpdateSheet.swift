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
                        UpdateChangelogCard(entry: $0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            UpdateSheetActions(model: model)
        }
        .padding(20)
        .frame(minWidth: 520, minHeight: 460)
    }
}
