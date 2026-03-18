import Foundation

extension Double {
    var formattedRPM: String {
        String(localized: "\(Int64(rounded())) RPM")
    }
}
