import ScrechKit

struct FanMetricRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        GridRow {
            Text(title)
                .secondary()
            Text(value)
        }
    }
}
