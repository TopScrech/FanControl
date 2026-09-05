import ScrechKit
#if !SANDBOXED_APP
import CoreSMC
#endif

struct AllFansCurrentSpeedCard: View {
    let fans: [Fan]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Current speed", systemImage: "speedometer")
                .headline()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(fans) { fan in
                    HStack(spacing: 12) {
                        Text("Fan \(fan.userFacingID)")
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
}
