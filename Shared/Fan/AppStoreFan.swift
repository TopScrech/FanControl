#if APP_STORE
// Transport-only model — the sandboxed app does not link the hardware controller
nonisolated struct Fan: Identifiable, Equatable, Sendable {
    let id: Int
    let minRPM: Double
    let maxRPM: Double
    let currentRPM: Double
    let targetRPM: Double
    let mode: UInt8
    
    init(id: Int, minRPM: Double, maxRPM: Double, currentRPM: Double, targetRPM: Double, mode: UInt8) {
        self.id = id
        self.minRPM = minRPM
        self.maxRPM = maxRPM
        self.currentRPM = currentRPM
        self.targetRPM = targetRPM
        self.mode = mode
    }
    
    var displayName: String {
        "Fan \(id)"
    }
    
    var modeName: String {
        switch mode {
        case 0: "Auto"
        case 1: "Manual"
        case 3: "System"
        default: "Mode \(mode)"
        }
    }
}

#endif
