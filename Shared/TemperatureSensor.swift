import CoreSMC

extension TemperatureSensor {
    nonisolated init(snapshot: TemperatureSensorSnapshot) {
        self.init(
            key: snapshot.key,
            celsius: snapshot.celsius,
            displayName: snapshot.displayName
        )
    }
}
