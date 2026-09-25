import ScrechKit

struct TemperatureRangeSlider: View {
    @AppStorage("temperatureUnit") private var temperatureUnitRawValue = TemperatureUnit.celsius.rawValue
    
    let bounds: ClosedRange<Int>
    @Binding var minimumValue: Int
    @Binding var maximumValue: Int
    var currentValue: Double?
    
    private let thumbSize = 20.0
    private let trackHeight = 6.0
    
    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(trackGradient)
                        .opacity(0.22)
                        .frame(height: trackHeight)
                    
                    Capsule()
                        .fill(trackGradient)
                        .frame(height: trackHeight)
                        .mask(alignment: .leading) {
                            Capsule()
                                .frame(width: selectedTrackWidth(in: geometry.size.width))
                                .offset(x: minimumThumbPosition(in: geometry.size.width))
                        }
                    
                    if let currentValue {
                        Capsule()
                            .fill(.primary)
                            .frame(width: 2, height: 14)
                            .offset(x: position(for: currentValue, width: geometry.size.width) - 1)
                            .help("Current temperature")
                            .animation(.smooth, value: currentValue)
                    }
                    
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
                .coordinateSpace(.named(Self.coordinateSpace))
            }
            .frame(height: thumbSize)
            .padding(.horizontal, thumbSize / 2)
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quiet below")
                        .caption()
                        .secondary()
                    
                    Text(displayTemperature(minimumValue))
                        .title3(.semibold)
                        .foregroundStyle(Double(minimumValue).temperatureTint)
                }
                
                Spacer(minLength: 0)
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Full speed above")
                        .caption()
                        .secondary()
                    
                    Text(displayTemperature(maximumValue))
                        .title3(.semibold)
                        .foregroundStyle(Double(maximumValue).temperatureTint)
                }
            }
            .monospacedDigit()
        }
    }
    
    private var trackGradient: LinearGradient {
        let span = Double(bounds.upperBound - bounds.lowerBound)
        
        let stops = stride(from: bounds.lowerBound, through: bounds.upperBound, by: 5).map {
            Gradient.Stop(color: Double($0).temperatureTint, location: Double($0 - bounds.lowerBound) / span)
        }
        
        return LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing)
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
            .fill(.white)
            .frame(width: thumbSize, height: thumbSize)
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            .offset(x: thumbPosition(for: value, width: width) - thumbSize / 2)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.coordinateSpace))
                    .onChanged { value in
                        update(value.location.x, width)
                    }
            )
    }
    
    private static let coordinateSpace = "TemperatureRangeSlider"
    
    private func position(for celsius: Double, width: CGFloat) -> CGFloat {
        guard bounds.upperBound > bounds.lowerBound, width > 0 else { return 0 }
        
        let progress = (celsius - Double(bounds.lowerBound)) / Double(bounds.upperBound - bounds.lowerBound)
        return min(max(progress * width, 0), width)
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
