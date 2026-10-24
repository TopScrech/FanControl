import SwiftUI

struct RemoteMacCard: View {
    @Environment(RemoteControlViewModel.self) private var model

    let mac: RemoteMacState
    
    var body: some View {
        HStack {
            Image(systemName: "desktopcomputer")
                .imageScale(.large)
            
            VStack(alignment: .leading) {
                Text(model.displayName(for: mac))
                
                Text(mac.isOnline ? "Online" : "Last seen \(mac.updatedAt.formatted(.relative(presentation: .named)))")
                    .foregroundStyle(mac.isOnline ? .green : .secondary)
            }
        }
    }
}
