import SwiftUI

struct DemoMacListView: View {
    @State private var model = RemoteControlViewModel.demo()

    var body: some View {
        RemoteHomeView()
            .environment(model)
    }
}
