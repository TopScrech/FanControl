import ScrechKit

struct FanActionCardView: View {
    let setAuto: () -> Void
    let setMin: () -> Void
    let setFull: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Control")
                .font(.headline)
            
            HStack(spacing: 10) {
                Button("Auto", action: setAuto)
                    .buttonStyle(.borderedProminent)
                
                Button("Min", action: setMin)
                
                Button("Full", action: setFull)
            }
            .controlSize(.large)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}
