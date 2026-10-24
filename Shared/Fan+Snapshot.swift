import CoreSMC

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
