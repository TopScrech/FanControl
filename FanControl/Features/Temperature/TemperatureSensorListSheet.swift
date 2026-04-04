import ScrechKit

struct TemperatureSensorListSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    @AppStorage("showsTemperatureSensorIcons") private var showsTemperatureSensorIcons = false
    
    let sensors: [TemperatureSensor]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Temperature sensors")
                    .headline()
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .padding(4)
                }
                .keyboardShortcut("w", modifiers: .command)
                .buttonBorderShape(.circle)
                .footnote()
            }
            
            ScrollView {
                TemperatureSensorList(
                    sensors: sensors,
                    showsTemperatureTenths: temperaturePrecision.showsTenths,
                    showsIcons: showsTemperatureSensorIcons
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
        }
        .padding()
        .frame(minWidth: 320, idealWidth: 320, maxWidth: 320, minHeight: 420, alignment: .topLeading)
        .background(ContentViewBackground())
    }
    
    private var temperaturePrecision: TemperaturePrecision {
        TemperaturePrecision(rawValue: temperaturePrecisionRawValue) ?? .whole
    }
}
