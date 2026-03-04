import Foundation

enum FanControlXPCInterface {
    static func make() -> NSXPCInterface {
        let interface = NSXPCInterface(with: FanControlXPCProtocol.self)
        let classes = NSSet(array: [NSArray.self, FanSnapshot.self, TemperatureSensorSnapshot.self]) as! Set<AnyHashable>
        
        interface.setClasses(
            classes,
            for: #selector(FanControlXPCProtocol.readFans(withReply:)),
            argumentIndex: 0,
            ofReply: true
        )
        
        interface.setClasses(
            classes,
            for: #selector(FanControlXPCProtocol.readTemperatureSensors(withReply:)),
            argumentIndex: 0,
            ofReply: true
        )
        
        return interface
    }
}
