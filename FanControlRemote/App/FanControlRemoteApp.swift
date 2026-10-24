import SwiftUI
import Appearance

@main
struct FanControlRemoteApp: App {
    @AppStorage("appearance") private var appearance: Appearance = .system
    @AppStorage("hasEnabledRemoteControl") private var hasEnabledRemoteControl = false
    @State private var model = RemoteControlViewModel()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasEnabledRemoteControl {
                    RemoteHomeView()
                    .environment(model)
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
            .preferredColorScheme(appearance.scheme)
        }
    }
}
