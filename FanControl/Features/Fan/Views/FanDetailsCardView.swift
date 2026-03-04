import ScrechKit
import CoreSMC

struct FanDetailsCardView: View {
    let fan: Fan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Status", systemImage: "gauge.with.dots.needle.bottom.50percent")
                .headline()
            
            VStack(alignment: .leading, spacing: 8) {
                FanMetricRowView("Mode", value: fan.modeName)
                FanMetricRowView("Current", value: fan.currentRPM.formattedRPM)
                FanMetricRowView("Target", value: fan.targetRPM.formattedRPM)
                FanMetricRowView("Min", value: fan.minRPM.formattedRPM)
                FanMetricRowView("Max", value: fan.maxRPM.formattedRPM)
            }
            .monospacedDigit()
        }
        .fanCardSurface()
    }
}
