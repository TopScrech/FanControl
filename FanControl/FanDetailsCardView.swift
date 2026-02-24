import ScrechKit

struct FanDetailsCardView: View {
    let fan: Fan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status")
                .font(.headline)
            
            Grid(alignment: .leading, horizontalSpacing: 26, verticalSpacing: 8) {
                FanMetricRowView(title: "Mode", value: fan.modeName)
                FanMetricRowView(title: "Current", value: fan.currentRPM.formattedRPM)
                FanMetricRowView(title: "Target", value: fan.targetRPM.formattedRPM)
                FanMetricRowView(title: "Min", value: fan.minRPM.formattedRPM)
                FanMetricRowView(title: "Max", value: fan.maxRPM.formattedRPM)
            }
            .monospacedDigit()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}
