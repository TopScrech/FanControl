import Foundation

struct TemperatureSensor: Identifiable, Equatable, Comparable, Sendable {
    let key: String
    let celsius: Double
    let displayName: String
    
    var id: String {
        "\(displayName):\(key)"
    }
    
    static func < (lhs: TemperatureSensor, rhs: TemperatureSensor) -> Bool {
        let displayNameOrder = lhs.displayName.localizedStandardCompare(rhs.displayName)
        
        if displayNameOrder != .orderedSame {
            return displayNameOrder == .orderedAscending
        }
        
        return lhs.key.localizedStandardCompare(rhs.key) == .orderedAscending
    }
}
