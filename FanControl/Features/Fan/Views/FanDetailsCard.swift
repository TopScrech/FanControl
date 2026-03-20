import ScrechKit
import CoreSMC

struct FanDetailsCard: View {
    let fan: Fan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Status", systemImage: "gauge.with.dots.needle.bottom.50percent")
                .headline()
            
            VStack(alignment: .leading, spacing: 8) {
                FanMetricRow(String(localized: "Mode"), value: fan.localizedModeName)
                FanMetricRow(String(localized: "Current"), value: fan.currentRPM.formattedRPM)
                FanMetricRow(String(localized: "Target"), value: fan.targetRPM.formattedRPM)
                FanMetricRow(String(localized: "Min"), value: fan.minRPM.formattedRPM)
                FanMetricRow(String(localized: "Max"), value: fan.maxRPM.formattedRPM)
            }
            .monospacedDigit()
        }
        .fanCardSurface()
    }
}
