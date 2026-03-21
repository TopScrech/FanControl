import SwiftUI

struct MenuBarRenderedLabelContentView: View {
    let systemImage: String
    let speeds: [String]
    let width: CGFloat
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .imageScale(.medium)
            
            if !speeds.isEmpty {
                MenuBarFanSpeedTextView(speeds: speeds)
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
