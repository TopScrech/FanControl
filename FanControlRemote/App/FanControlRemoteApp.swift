import SwiftUI

@main
struct FanControlRemoteApp: App {
    @AppStorage("hasEnabledRemoteControl") private var hasEnabledRemoteControl = false
    @State private var model = RemoteControlViewModel()

    var body: some Scene {
        WindowGroup {
            if hasEnabledRemoteControl {
                NavigationStack {
                    RemoteMacList(model: model)
                }
                .task {
                    await model.observe()
                }
            } else {
                ContentView()
            }
        }
    }
}
