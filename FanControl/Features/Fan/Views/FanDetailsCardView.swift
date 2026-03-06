import ScrechKit
import CoreSMC

struct FanDetailsCardView: View {
    let fan: Fan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Status", systemImage: "gauge.with.dots.needle.bottom.50percent")
                .headline()
            
            VStack(alignment: .leading, spacing: 8) {
                FanMetricRowView(String(localized: "Mode"), value: fan.modeName)
                FanMetricRowView(String(localized: "Current"), value: fan.currentRPM.formattedRPM)
                FanMetricRowView(String(localized: "Target"), value: fan.targetRPM.formattedRPM)
                FanMetricRowView(String(localized: "Min"), value: fan.minRPM.formattedRPM)
                FanMetricRowView(String(localized: "Max"), value: fan.maxRPM.formattedRPM)
            }
            .monospacedDigit()
        }
        .fanCardSurface()
    }
}
