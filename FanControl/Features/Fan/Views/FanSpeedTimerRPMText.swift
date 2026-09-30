import ScrechKit

struct FanSpeedTimerRPMText: View {
    let rpmRange: ClosedRange<Double>

    private let rpmFormat = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))

    var body: some View {
        if rpmRange.lowerBound == rpmRange.upperBound {
            Text("\(rpmRange.lowerBound, format: rpmFormat) RPM")
        } else {
            Text("\(rpmRange.lowerBound, format: rpmFormat)–\(rpmRange.upperBound, format: rpmFormat) RPM")
        }
    }
}
