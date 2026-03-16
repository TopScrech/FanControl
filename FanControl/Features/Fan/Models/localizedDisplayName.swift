import Foundation
import CoreSMC

extension Fan {
    var localizedDisplayName: String {
        let localizedFan = String(localized: "Fan")

        return "\(localizedFan) \(id + 1)"
    }
}
