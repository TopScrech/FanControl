struct Fan: Identifiable, Equatable {
    let id: Int
    let minRPM: Double
    let maxRPM: Double
    let currentRPM: Double
    let targetRPM: Double
    let mode: UInt8
    
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

extension Fan {
    nonisolated init(snapshot: FanSnapshot) {
        self.init(
            id: snapshot.id,
            minRPM: snapshot.minRPM,
            maxRPM: snapshot.maxRPM,
            currentRPM: snapshot.currentRPM,
            targetRPM: snapshot.targetRPM,
            mode: snapshot.mode
        )
    }
}
