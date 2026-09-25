import SwiftUI

extension Double {
    // Cold to hot ramp interpolated between fixed Celsius stops
    var temperatureTint: Color {
        let stops: [(celsius: Double, rgb: (Double, Double, Double))] = [
            (28, (100, 210, 255)),
            (36, (99, 230, 190)),
            (46, (255, 214, 10)),
            (60, (255, 159, 10)),
            (75, (255, 69, 58))
        ]

        guard let first = stops.first, let last = stops.last else { return .primary }

        if self <= first.celsius {
            return Self.color(first.rgb)
        }

        for (lower, upper) in zip(stops, stops.dropFirst()) where self <= upper.celsius {
            let progress = (self - lower.celsius) / (upper.celsius - lower.celsius)

            return Self.color((
                lower.rgb.0 + (upper.rgb.0 - lower.rgb.0) * progress,
                lower.rgb.1 + (upper.rgb.1 - lower.rgb.1) * progress,
                lower.rgb.2 + (upper.rgb.2 - lower.rgb.2) * progress
            ))
        }

        return Self.color(last.rgb)
    }

    private static func color(_ rgb: (Double, Double, Double)) -> Color {
        Color(red: rgb.0 / 255, green: rgb.1 / 255, blue: rgb.2 / 255)
    }
}
