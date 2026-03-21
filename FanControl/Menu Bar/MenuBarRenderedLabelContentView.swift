import SwiftUI

struct MenuBarRenderedLabelContentView: View {
    let systemImage: String
    let speeds: [String]
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .imageScale(.medium)
            
            if !speeds.isEmpty {
                MenuBarFanSpeedTextView(speeds: speeds)
            }
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .fixedSize()
    }
}
