import SwiftUI
import CoreSMC

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
    
    var localizedModeName: LocalizedStringKey {
        switch mode {
        case 0: "Auto"
        case 1: "Manual"
        case 3: "System"
        default: "Mode \(mode)"
        }
    }
}
