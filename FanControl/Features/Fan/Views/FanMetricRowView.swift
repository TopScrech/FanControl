import ScrechKit

struct FanMetricRowView: View {
    private let title: String
    private let value: String
    private let valueColor: Color
    
    init(_ title: String, value: String, valueColor: Color = .primary) {
        self.title = title
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack(spacing: 12) {
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
