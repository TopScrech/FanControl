import Foundation

enum FanControlXPCConstants {
    static let machServiceName = "dev.topscrech.FanControl.helper"
    static let launchdPlistName = "dev.topscrech.FanControl.helper.plist"
}

enum FanControlXPCInterface {
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

@objc(FanControlXPCProtocol)
protocol FanControlXPCProtocol {
    func readFans(withReply reply: @escaping ([FanSnapshot]?, String?) -> Void)
    func setManualRPM(fanID: Int, rpm: Double, withReply reply: @escaping (String?) -> Void)
    func setAuto(fanID: Int, withReply reply: @escaping (String?) -> Void)
    func keepAliveManualOverride(withReply reply: @escaping (String?) -> Void)
}

final class FanSnapshot: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
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
    
    convenience init(fan: Fan) {
        self.init(
            id: fan.id,
            minRPM: fan.minRPM,
            maxRPM: fan.maxRPM,
            currentRPM: fan.currentRPM,
            targetRPM: fan.targetRPM,
            mode: fan.mode
        )
    }
    
    convenience init?(coder: NSCoder) {
        let id = coder.decodeInteger(forKey: "id")
        let minRPM = coder.decodeDouble(forKey: "minRPM")
        let maxRPM = coder.decodeDouble(forKey: "maxRPM")
        let currentRPM = coder.decodeDouble(forKey: "currentRPM")
        let targetRPM = coder.decodeDouble(forKey: "targetRPM")
        let mode = UInt8(truncatingIfNeeded: coder.decodeInteger(forKey: "mode"))
        
        self.init(
            id: id,
            minRPM: minRPM,
            maxRPM: maxRPM,
            currentRPM: currentRPM,
            targetRPM: targetRPM,
            mode: mode
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(id, forKey: "id")
        coder.encode(minRPM, forKey: "minRPM")
        coder.encode(maxRPM, forKey: "maxRPM")
        coder.encode(currentRPM, forKey: "currentRPM")
        coder.encode(targetRPM, forKey: "targetRPM")
        coder.encode(Int(mode), forKey: "mode")
    }
}
