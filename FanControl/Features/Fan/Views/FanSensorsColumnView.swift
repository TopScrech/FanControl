import ScrechKit

struct FanSensorsColumnView: View {
    let sensors: [TemperatureSensor]
    
    var body: some View {
        FanTemperatureCardView(sensors: sensors)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
