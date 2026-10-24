import SwiftUI

extension Double {
    var formattedRPM: LocalizedStringKey {
        "\(Int64(rounded())) RPM"
    }
}
