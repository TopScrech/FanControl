import ScrechKit

struct FanPromotionCard: View {
    let title: LocalizedStringKey
    let linkTitle: LocalizedStringKey
    let destination: URL?
    var showsShareButton = false
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text(title)
                    .headline()
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Button("Dismiss", systemImage: "xmark", action: dismiss)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .secondary()
                    .help("Don't show again")
            }

            if let destination {
                HStack {
                    Link(linkTitle, destination: destination)

                    if showsShareButton {
                        ShareLink(item: destination) {
                            Text("Share")
                        }
                        .help("Share App Store link")
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(.blue)
            }
        }
        .fanCardSurface()
    }
}
