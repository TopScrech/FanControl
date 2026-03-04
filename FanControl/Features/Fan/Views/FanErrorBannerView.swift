import ScrechKit

struct FanErrorBannerView: View {
    let error: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            
            Text(error)
                .callout()
                .foregroundStyle(.red)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("Copy", action: copyErrorToClipboard)
                .controlSize(.small)
                .help("Copy error message")
            
            Button("Dismiss", systemImage: "xmark", action: onDismiss)
                .buttonStyle(.plain)
                .controlSize(.small)
                .help("Dismiss")
                .padding(.top, 2)
                .padding(.leading, 2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.red.opacity(0.12), in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.red.opacity(0.25), lineWidth: 1)
        }
    }
    
    private func copyErrorToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(error, forType: .string)
        onDismiss()
    }
}
