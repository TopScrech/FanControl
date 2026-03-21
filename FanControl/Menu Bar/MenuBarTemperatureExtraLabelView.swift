import SwiftUI

struct MenuBarTemperatureExtraLabelView: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    
    let sensors: [TemperatureSensor]
    
    var body: some View {
        if let renderedLabelImage {
            Image(nsImage: renderedLabelImage)
                .renderingMode(.template)
        } else {
            Image(systemName: "thermometer.medium")
        }
    }
    
    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }
    
    private var temperaturePrecision: TemperaturePrecision {
        TemperaturePrecision(rawValue: temperaturePrecisionRawValue) ?? .whole
    }
    
    private var cpuText: String {
        formattedTemperature(for: .cpu)
    }
    
    private var gpuText: String {
        formattedTemperature(for: .gpu)
    }
    
    private var renderedLabelImage: NSImage? {
        guard !sensors.isEmpty else { return nil }
        
        let renderer = ImageRenderer(
            content: MenuBarTemperatureRenderedLabelContentView(
                cpuText: cpuText,
                gpuText: gpuText
            )
        )
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        
        guard let image = renderer.nsImage else { return nil }
        
        image.isTemplate = true
        return image
    }
    
    private func formattedTemperature(for category: TemperatureSensorCategory) -> String {
        guard let celsius = category.averageCelsius(in: sensors) else { return "--" }
        
        let fractionLength = temperaturePrecision.showsTenths ? 1 : 0
        let value: Double
        let unitText: String
        
        switch temperatureUnit {
        case .celsius:
            value = celsius
            unitText = "°C"
            
        case .fahrenheit:
            value = celsius * 9 / 5 + 32
            unitText = "°F"
            
        case .kelvin:
            value = celsius + 273.15
            unitText = "K"
        }
        
        return "\(value.formatted(.number.precision(.fractionLength(fractionLength))))\(unitText)"
    }
}
