import SwiftUI

@main
struct FanControlRemoteApp: App {
    @State private var model = RemoteControlViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RemoteMacList(model: model)
            }
            .task {
                await model.observe()
            }
        }
    }
}
