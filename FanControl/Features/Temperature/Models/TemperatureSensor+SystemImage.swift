extension TemperatureSensor {
    var systemImage: String {
        if let category = TemperatureSensorCategory.allCases.first(where: { $0.contains(sensor: self) }) {
            return category.systemImage
        }
        
        let normalizedName = displayName.lowercased()
        
        if normalizedName.contains("memory") || normalizedName.contains("ram") {
            return "memorychip"
        }
        
        if normalizedName.contains("storage") || normalizedName.contains("ssd") || normalizedName.contains("disk") || normalizedName.contains("nand") {
            return "internaldrive"
        }
        
        if normalizedName.contains("display") || normalizedName.contains("screen") {
            return "display"
        }
        
        if normalizedName.contains("wireless") || normalizedName.contains("wifi") || normalizedName.contains("bluetooth") {
            return "wifi"
        }
        
        if normalizedName.contains("keyboard") {
            return "keyboard"
        }
        
        if normalizedName.contains("trackpad") || normalizedName.contains("palm") {
            return "hand.raised"
        }
        
        if normalizedName.contains("camera") {
            return "camera"
        }
        
        if normalizedName.contains("power") || normalizedName.contains("charger") || normalizedName.contains("adapter") {
            return "bolt"
        }
        
        return "thermometer.medium"
    }
}
