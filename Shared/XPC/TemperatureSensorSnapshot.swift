import Foundation
import CoreSMC

final class TemperatureSensorSnapshot: NSObject, NSSecureCoding {
    static var supportsSecureCoding = true
    
    let key: String
    let celsius: Double
    let displayName: String
    
    init(key: String, celsius: Double, displayName: String) {
        self.key = key
        self.celsius = celsius
        self.displayName = displayName
    }
    
    convenience init(sensor: TemperatureSensor) {
        self.init(
            key: sensor.key,
            celsius: sensor.celsius,
            displayName: sensor.displayName
        )
    }
    
    convenience init?(coder: NSCoder) {
        guard let key = coder.decodeObject(of: NSString.self, forKey: "key") as String? else {
            return nil
        }
        
        self.init(
            key: key,
            celsius: coder.decodeDouble(forKey: "celsius"),
            displayName: coder.decodeObject(of: NSString.self, forKey: "displayName") as String? ?? key
        )
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(key as NSString, forKey: "key")
        coder.encode(celsius, forKey: "celsius")
        coder.encode(displayName as NSString, forKey: "displayName")
    }
}
