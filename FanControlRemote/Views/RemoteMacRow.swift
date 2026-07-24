import SwiftUI

struct RemoteMacRow: View {
    let mac: RemoteMacState
    
    var body: some View {
        HStack {
            Image(systemName: "desktopcomputer")
                .imageScale(.large)
            
            VStack(alignment: .leading) {
                Text(mac.name)
                
                Text(mac.isOnline ? "Online" : "Last seen \(mac.updatedAt.formatted(.relative(presentation: .named)))")
                    .foregroundStyle(mac.isOnline ? .green : .secondary)
            }
        }
    }
}
