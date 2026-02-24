import ScrechKit

struct FanErrorBannerView: View {
    let error: String
    
    var body: some View {
        Text(error)
            .font(.callout)
            .foregroundStyle(.red)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.red.opacity(0.12), in: .rect(cornerRadius: 10))
    }
}
