import SwiftUI

@main
struct FanControlRemoteApp: App {
    @AppStorage("hasEnabledRemoteControl") private var hasEnabledRemoteControl = false
    @State private var model = RemoteControlVM()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasEnabledRemoteControl {
                    NavigationStack {
                        RemoteMacList(model: model)
                    }
                    .task {
                        await model.observe()
                    }
                    .transition(.opacity)
                } else {
                    NavigationStack {
                        OnboardingView()
                    }
                    .transition(.opacity)
                }
            }
            .animation(.smooth, value: hasEnabledRemoteControl)
        }
    }
}
