import ScrechKit
import CoreSMC

struct AllFansCurrentSpeedCardView: View {
    let fans: [Fan]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Current speed", systemImage: "speedometer")
                .headline()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(fans) {
                    FanMetricRowView($0.localizedDisplayName, value: $0.currentRPM.formattedRPM)
                }
            }
            .monospacedDigit()
        }
        .fanCardSurface()
    }
}
