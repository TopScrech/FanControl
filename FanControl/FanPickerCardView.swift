import ScrechKit

struct FanPickerCardView: View {
    let fans: [Fan]
    @Binding var selectedFanID: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fan")
                .font(.headline)
            
            Picker("Fan", selection: $selectedFanID) {
                ForEach(fans) {
                    Text($0.displayName)
                        .tag($0.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}
