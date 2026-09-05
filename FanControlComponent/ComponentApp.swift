import SwiftUI

@main
struct ComponentApp: App {
    @NSApplicationDelegateAdaptor(ComponentAppDelegate.self) private var delegate
    @State private var model = ComponentModel.shared

    var body: some Scene {
        WindowGroup {
            ComponentView()
                .environment(model)
        }
        .windowResizability(.contentSize)
    }
}
