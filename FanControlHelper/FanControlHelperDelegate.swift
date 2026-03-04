import OSLog

final class FanControlHelperDelegate: NSObject, NSXPCListenerDelegate {
    private static let logger = Logger(subsystem: "FanControl", category: "SMCHelper")
    private let service = FanControlHelperService()
    
    nonisolated func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = FanControlXPCInterface.make()
        newConnection.exportedObject = service
        newConnection.resume()
        Self.logger.info("Accepted helper connection")
        return true
    }
}
