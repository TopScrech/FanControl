import ScrechKit

struct AverageTemperatureCard: View {
    let rows: [TemperatureAverageRow]
    let showsIcons: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rows) {
                    FanMetricRow(
                        $0.title,
                        systemImage: showsIcons ? $0.systemImage : nil,
                        value: $0.value
                    )
                }
            }
            .monospacedDigit()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}
