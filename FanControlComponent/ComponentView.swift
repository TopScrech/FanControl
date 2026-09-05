import SwiftUI

struct ComponentView: View {
    @Environment(ComponentModel.self) private var model

    var body: some View {
        VStack(alignment: .leading) {
            Label("Installing FanControl components", systemImage: "fan")
                .font(.title)
            Text(model.status)
                .textSelection(.enabled)
            if model.isBusy { ProgressView() }
            if model.needsApproval {
                Button("Open System Settings", systemImage: "gear", action: model.openApprovalSettings)
            }
            if !model.isBusy && !model.isFinished {
                Button("Retry installation", systemImage: "arrow.clockwise") {
                    Task { await model.install() }
                }
            }
        }
        .padding()
        .frame(minWidth: 400)
    }
}
