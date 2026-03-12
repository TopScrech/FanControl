import Foundation
import CoreSMC

extension Fan {
    var localizedDisplayName: String {
        let localizedFan = String(localized: "Fan")
        
        return displayName.replacingOccurrences(
            of: #"(?i)^fan\b"#,
            with: localizedFan,
            options: .regularExpression
        )
    }
}
