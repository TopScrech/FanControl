import SwiftUI

struct RemoteFanActionButtons: View {
    let fanID: Int
    let mac: RemoteMacState
    @Bindable var model: RemoteControlViewModel
    
    var body: some View {
        HStack {
            RemoteFanModeButton(
                "Auto",
                systemImage: "fan",
                isSelected: activeAction == .automatic,
                action: setAutomatic
            )
            
            RemoteFanModeButton(
                "Min",
                systemImage: "arrow.down",
                isSelected: activeAction == .minimum,
                action: setMinimum
            )
            
            RemoteFanModeButton(
                "Max",
                systemImage: "arrow.up",
                isSelected: activeAction == .maximum,
                action: setMaximum
            )
        }
        .foregroundStyle(.primary)
        .disabled(!mac.isOnline || model.pendingCommand != nil)
    }
    
    private var activeAction: RemoteFanAction? {
        model.activeAction(fanID: fanID, in: mac)
    }
    
    private func setAutomatic() {
        send(.automatic)
    }
    
    private func setMinimum() {
        send(.minimum)
    }
    
    private func setMaximum() {
        send(.maximum)
    }
    
    private func send(_ action: RemoteFanAction) {
        Task {
            await model.send(action: action, fanID: fanID, to: mac)
        }
    }
}
