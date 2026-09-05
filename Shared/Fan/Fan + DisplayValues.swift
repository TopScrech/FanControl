import Foundation
#if !SANDBOXED_APP
import CoreSMC
#endif

extension Fan {
    var userFacingID: Int {
        id + 1
    }
    
    var cliDisplayName: String {
        "Fan \(userFacingID)"
    }
    
    var cliModeDescription: String {
        switch mode {
        case 0, 3: "Auto"
        default: "Manual"
        }
    }
    
    var localizedModeName: String {
        switch mode {
        case 0: String(localized: "Auto")
        case 1: String(localized: "Manual")
        case 3: String(localized: "System")
        default: "\(String(localized: "Mode")) \(mode)"
        }
    }
}
