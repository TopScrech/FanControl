import ScrechKit

struct MenuBarFanSpeedTextView: View {
    let speeds: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: -2) {
            ForEach(speeds.indices, id: \.self) {
                Text(speeds[$0])
                    .fontSize(8)
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}
