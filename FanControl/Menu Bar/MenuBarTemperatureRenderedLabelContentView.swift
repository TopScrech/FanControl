import SwiftUI

struct MenuBarTemperatureRenderedLabelContentView: View {
    let cpuText: String
    let gpuText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CPU: \(cpuText)")
            Text("GPU: \(gpuText)")
        }
        .font(.caption2)
        .monospacedDigit()
        .foregroundStyle(.black)
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .fixedSize()
    }
}
