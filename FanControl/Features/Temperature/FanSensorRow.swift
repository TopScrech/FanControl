import ScrechKit

struct FanSensorRow: View {
    let title: String
    let systemImage: String?
    let value: String
    let celsius: Double?
    let showsSeparator: Bool

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .secondary()
                    .frame(width: 16)
            }

            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)

            TemperaturePill(value: value, celsius: celsius)
        }
        .frame(minHeight: 34)
        .overlay(alignment: .top) {
            if showsSeparator {
                Divider()
                    .padding(.leading, systemImage == nil ? 0 : 26)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
