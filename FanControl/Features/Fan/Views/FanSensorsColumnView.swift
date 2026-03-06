import ScrechKit

struct FanSensorsColumnView: View {
    let sensors: [TemperatureSensor]
    
    var body: some View {
        ScrollView {
            FanTemperatureCardView(sensors: sensors)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
