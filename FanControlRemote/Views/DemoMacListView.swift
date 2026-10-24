import SwiftUI

struct DemoMacListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var model = RemoteControlViewModel.demo()

    var body: some View {
        List(model.macs) { mac in
            NavigationLink(value: DemoMacDestination(macID: mac.id)) {
                RemoteMacCard(mac: mac)
            }
        }
        .navigationTitle("FanControl")
        .navigationBarBackButtonHidden()
        .overlay(alignment: .leading) {
            Color.clear
                .frame(width: 24)
                .contentShape(.rect)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            let backDistance = layoutDirection == .leftToRight
                                ? value.translation.width
                                : -value.translation.width

                            if backDistance > 80, backDistance > abs(value.translation.height) {
                                dismiss()
                            }
                        }
                )
        }
        .accessibilityAction(.escape) {
            dismiss()
        }
        .navigationDestination(for: DemoMacDestination.self) {
            RemoteMacDetailView(macID: $0.macID)
                .environment(model)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Show Setup", systemImage: "questionmark.circle") {}
                    .labelStyle(.iconOnly)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Settings", systemImage: "gearshape") {}
                    .labelStyle(.iconOnly)
            }
        }
    }
}
