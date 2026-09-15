import ScrechKit

struct OnboardingView: View {
    @AppStorage("hasEnabledRemoteControl") private var hasEnabledRemoteControl = false
    @State private var didCopyLink = false
    
    private let websiteURL = URL(string: "https://fancontrol.dev?source=fancontrol-ios")
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                SetupStepView(
                    number: 1,
                    title: "Install FanControl on your Mac",
                    detail: "Download and install the Mac app before continuing"
                ) {
                    if let websiteURL {
                        Link("Open fancontrol.dev", destination: websiteURL)
                            .buttonStyle(.borderedProminent)
                            .semibold()
                        
                        HStack {
                            Button(
                                didCopyLink ? "Copied" : "Copy link",
                                systemImage: didCopyLink ? "checkmark" : "doc.on.doc"
                            ) {
                                UIPasteboard.general.string = websiteURL.absoluteString
                                didCopyLink = true
                            }
                            .buttonStyle(.bordered)
                            .semibold()
                            
                            ShareLink(item: websiteURL) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                            .semibold()
                        }
                    }
                }
                
                SetupStepView(
                    number: 2,
                    title: "Enable Remote Control",
                    detail: "In FanControl for Mac, open Settings and turn on Remote Control"
                ) {
                    EmptyView()
                }
                
                SetupStepView(
                    number: 3,
                    title: "Enable Background Activity",
                    detail: "Adjust fan speed and allow background activity when requested by the system. Missed the alert? Enable FanControl in System Settings → General → Login Items → Allow in Background"
                ) {
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Set up Remote Fan Control")
        .safeAreaInset(edge: .bottom) {
            Button {
                hasEnabledRemoteControl = true
            } label: {
                Text("Done")
                    .title3(.bold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.bar)
        }
    }
}
