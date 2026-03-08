import ScrechKit

extension Double {
    var temperatureValueColor: Color {
        if self > 95 {
            .temperatureCritical
        } else if self > 85 {
            .temperatureWarning
        } else {
            .primary
        }
    }
}

private extension Color {
    static let temperatureCritical = Color(0xFF4040)
    static let temperatureWarning = Color(0xFFE67C)
}
