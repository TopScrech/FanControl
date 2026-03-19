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
}
