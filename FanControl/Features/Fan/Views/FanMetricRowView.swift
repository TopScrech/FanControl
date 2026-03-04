import ScrechKit

struct FanMetricRowView: View {
    private let title: String
    private let value: String
    
    init(_ title: String, value: String) {
        self.title = title
        self.value = value
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
