import ScrechKit

struct FanMetricRow: View {
    private let title: String
    private let systemImage: String?
    private let value: String
    private let valueColor: Color
    
    init(_ title: String, systemImage: String? = nil, value: String, valueColor: Color = .primary) {
        self.title = title
        self.systemImage = systemImage
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
            }
            
            Text(title)
                .secondary()
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer(minLength: 0)
            
            Text(value)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
