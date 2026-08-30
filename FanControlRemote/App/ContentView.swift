import SwiftUI
import UIKit

struct ContentView: View {
    @AppStorage("hasEnabledRemoteControl") private var hasEnabledRemoteControl = false
    @State private var didCopyLink = false

    private let websiteURL = URL(string: "https://fancontrol.dev")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Group {
                        if #available(iOS 18, *) {
                            Image(systemName: "fan.fill")
                                .symbolEffect(.rotate, options: .repeating)
                        } else {
                            Image(systemName: "fan.fill")
                        }
                    }
                    .font(.system(size: 52))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                    Text("Set up Remote Fan Control")
                        .font(.largeTitle)
                        .bold()

                    VStack {
                        SetupStepView(
                            number: 1,
                            title: "Install FanControl on your Mac",
                            detail: "Download and install the Mac app before continuing"
                        ) {
                            if let websiteURL {
                                Link("Open fancontrol.dev", destination: websiteURL)
                                    .buttonStyle(.borderedProminent)

                                HStack {
                                    Button(
                                        didCopyLink ? "Copied" : "Copy link",
                                        systemImage: didCopyLink ? "checkmark" : "doc.on.doc"
                                    ) {
                                        UIPasteboard.general.string = websiteURL.absoluteString
                                        didCopyLink = true
                                    }
                                    .buttonStyle(.bordered)

                                    ShareLink(item: websiteURL) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }
                                    .buttonStyle(.bordered)
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
                    .padding(.top)

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                hasEnabledRemoteControl = true
            } label: {
                Text("Done")
                    .font(.title3)
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.bar)
        }
    }
}
