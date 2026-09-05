import Foundation

final class FanControlHelperDelegate: NSObject, NSXPCListenerDelegate {
    private let engine: FanControlEngine
    private let temperatures = ComponentTemperatureReader()

    init(engine: FanControlEngine) { self.engine = engine }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.setCodeSigningRequirement(ComponentConfiguration.clientRequirement)
        let service = FanControlHelperService(engine: engine, temperatures: temperatures)
        let owner = service.owner
        let engine = engine
        connection.exportedInterface = FanControlXPCInterface.make()
        connection.exportedObject = service
        connection.invalidationHandler = {
            Task { @MainActor in engine.restore(owner: owner) }
        }
        connection.interruptionHandler = connection.invalidationHandler
        connection.resume()
        return true
    }
}
