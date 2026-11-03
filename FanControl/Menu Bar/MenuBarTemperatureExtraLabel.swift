import SwiftUI

struct MenuBarTemperatureExtraLabel: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    @AppStorage("temperaturePrecision") private var temperaturePrecisionRawValue = TemperaturePrecision.whole.rawValue
    
    @Environment(\.displayScale) private var displayScale
    @State private var renderedLabelImage: NSImage?
    @State private var renderedCPUText: String?
    @State private var renderedGPUText: String?
    @State private var renderedScale: CGFloat?

    let sensors: [TemperatureSensor]
    
    var body: some View {
        Group {
            if let renderedLabelImage {
                Image(nsImage: renderedLabelImage)
                    .renderingMode(.template)
            } else {
                Image(systemName: "thermometer.medium")
            }
        }
        .onChange(of: cpuText, initial: true) { updateRenderedLabel() }
        .onChange(of: gpuText) { updateRenderedLabel() }
        .onChange(of: sensors.isEmpty) { updateRenderedLabel() }
        .onChange(of: displayScale) { updateRenderedLabel() }
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
    
    private func updateRenderedLabel() {
        guard !sensors.isEmpty else {
            renderedLabelImage = nil
            renderedCPUText = nil
            renderedGPUText = nil
            renderedScale = nil
            return
        }

        let cpuText = cpuText
        let gpuText = gpuText
        guard renderedLabelImage == nil || renderedCPUText != cpuText ||
                renderedGPUText != gpuText || renderedScale != displayScale else { return }

        let renderer = ImageRenderer(
            content: MenuBarTemperatureRenderedLabel(
                cpuText: cpuText,
                gpuText: gpuText
            )
        )
        renderer.scale = displayScale
        
        guard let image = renderer.nsImage else { return }
        
        image.isTemplate = true
        renderedLabelImage = image
        renderedCPUText = cpuText
        renderedGPUText = gpuText
        renderedScale = displayScale
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
