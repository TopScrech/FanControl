import SwiftUI

struct MenuBarRenderedLabel: View {
    let systemImage: String
    let speeds: [String]
    let width: CGFloat
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .imageScale(.medium)
            
            if !speeds.isEmpty {
                MenuBarFanSpeedText(speeds: speeds)
            }
        }
        .frame(width: width, alignment: .leading)
        .foregroundStyle(.black)
        .padding(.leading, 2)
        .padding(.trailing, 0)
        .padding(.vertical, 1)
        .fixedSize()
    }
}
