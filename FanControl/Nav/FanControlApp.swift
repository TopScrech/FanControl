import SwiftUI

@main
struct FanControlApp: App {
    @State private var model = FanVM()
    
    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
        .windowResizability(.contentSize)
    }
}
