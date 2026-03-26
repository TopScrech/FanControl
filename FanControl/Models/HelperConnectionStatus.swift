enum HelperConnectionStatus {
    case runningAsRoot, connected, enabled, requiresApproval, notFound, notRegistered, unavailable
    
    var text: String {
        switch self {
        case .runningAsRoot: "Running as root"
        case .connected: "Connected"
        case .enabled: "Enabled, not connected"
        case .requiresApproval: "Needs approval"
        case .notFound: "Not found"
        case .notRegistered: "Not registered"
        case .unavailable: "Unavailable"
        }
    }
}
