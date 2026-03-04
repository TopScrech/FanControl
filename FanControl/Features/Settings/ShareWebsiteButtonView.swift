import ScrechKit

struct ShareWebsiteButtonView: View {
    private let websiteURL = URL(string: "https://fancontrol.dev")!
    
    var body: some View {
        ShareLink(
            item: websiteURL,
            subject: Text("FanControl"),
            message: Text("Check out FanControl")
        ) {
            HStack(spacing: 10) {
                Text("Share FanControl")
                
                Spacer(minLength: 0)
                
                Image(systemName: "square.and.arrow.up")
                    .semibold()
                    .secondary()
            }
        }
        .buttonStyle(.plain)
    }
}
