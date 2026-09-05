import Foundation

nonisolated enum FanControlXPCInterface {
    static func make() -> NSXPCInterface {
        let interface = NSXPCInterface(with: FanControlXPCProtocol.self)
        let classes = NSSet(array: [NSArray.self, FanSnapshot.self]) as! Set<AnyHashable>
        
        interface.setClasses(
            classes,
            for: #selector(FanControlXPCProtocol.readFans(withReply:)),
            argumentIndex: 0,
            ofReply: true
        )
        
        return interface
    }
}
