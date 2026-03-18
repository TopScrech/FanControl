import ScrechKit

struct TemperatureRangeSlider: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    
    let bounds: ClosedRange<Int>
    @Binding var minimumValue: Int
    @Binding var maximumValue: Int
    
    private let thumbSize = 18.0
    private let trackHeight = 6.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(displayTemperature(bounds.lowerBound))
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.primary.opacity(0.12))
                            .frame(height: trackHeight)
                        
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(
                                width: selectedTrackWidth(in: geometry.size.width),
                                height: trackHeight
                            )
                            .offset(x: minimumThumbPosition(in: geometry.size.width))
                        
                        thumb(
                            value: minimumValue,
                            width: geometry.size.width,
                            update: updateMinimumValue(_:width:)
                        )
                        
                        thumb(
                            value: maximumValue,
                            width: geometry.size.width,
                            update: updateMaximumValue(_:width:)
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
                
                Text(displayTemperature(bounds.upperBound))
            }
            .frame(height: 28)
            
            HStack {
                Text("Min \(displayTemperature(minimumValue))")
                
                Spacer(minLength: 0)
                
                Text("Max \(displayTemperature(maximumValue))")
            }
            .secondary()
            .caption()
            .monospacedDigit()
        }
    }
    
    private var temperatureUnit: TemperatureUnit {
        TemperatureUnit(rawValue: temperatureUnitRawValue) ?? .celsius
    }
    
    private func thumb(
        value: Int,
        width: CGFloat,
        update: @escaping (CGFloat, CGFloat) -> Void
    ) -> some View {
        Circle()
            .fill(.background)
            .overlay {
                Circle()
                    .stroke(.primary.opacity(0.18), lineWidth: 1)
            }
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
            .offset(x: thumbPosition(for: value, width: width) - thumbSize / 2)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        update(value.location.x, width)
                    }
            )
    }
    
    private func minimumThumbPosition(in width: CGFloat) -> CGFloat {
        thumbPosition(for: minimumValue, width: width)
    }
    
    private func maximumThumbPosition(in width: CGFloat) -> CGFloat {
        thumbPosition(for: maximumValue, width: width)
    }
    
    private func selectedTrackWidth(in width: CGFloat) -> CGFloat {
        max(0, maximumThumbPosition(in: width) - minimumThumbPosition(in: width))
    }
    
    private func thumbPosition(for value: Int, width: CGFloat) -> CGFloat {
        guard bounds.upperBound > bounds.lowerBound, width > 0 else { return 0 }
        
        let progress = CGFloat(value - bounds.lowerBound) / CGFloat(bounds.upperBound - bounds.lowerBound)
        return min(max(progress * width, 0), width)
    }
    
    private func value(for locationX: CGFloat, width: CGFloat) -> Int {
        guard width > 0 else { return bounds.lowerBound }
        
        let progress = min(max(locationX / width, 0), 1)
        let value = Double(bounds.lowerBound) + Double(progress) * Double(bounds.upperBound - bounds.lowerBound)
        return Int(value.rounded())
    }
    
    private func updateMinimumValue(_ locationX: CGFloat, width: CGFloat) {
        minimumValue = min(value(for: locationX, width: width), maximumValue)
    }
    
    private func updateMaximumValue(_ locationX: CGFloat, width: CGFloat) {
        maximumValue = max(value(for: locationX, width: width), minimumValue)
    }
    
    private func displayTemperature(_ celsiusValue: Int) -> String {
        "\(displayTemperatureValue(celsiusValue)) \(temperatureUnit.symbol)"
    }
    
    private func displayTemperatureValue(_ celsiusValue: Int) -> String {
        let value = switch temperatureUnit {
        case .celsius:
            Double(celsiusValue)
            
        case .fahrenheit:
            Double(celsiusValue) * 9 / 5 + 32
            
        case .kelvin:
            Double(celsiusValue) + 273.15
        }
        
        return value.formatted(.number.precision(.fractionLength(0)))
    }
}
