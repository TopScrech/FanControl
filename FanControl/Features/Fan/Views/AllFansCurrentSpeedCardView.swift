import ScrechKit
import CoreSMC

struct AllFansCurrentSpeedCardView: View {
    let fans: [Fan]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Current speed", systemImage: "speedometer")
                .headline()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(fans) { fan in
                    HStack(spacing: 12) {
                        fanLabel(fan)
                            .secondary()
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Spacer(minLength: 0)
                        
                        Text(fan.currentRPM.formattedRPM)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .monospacedDigit()
        }
        .fanCardSurface()
    }
    
    private func fanLabel(_ fan: Fan) -> Text {
        Text("Fan") + Text(" \(fan.userFacingID)")
    }
}
