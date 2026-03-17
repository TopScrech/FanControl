import Foundation

enum MacDeviceDescriptionProvider {
    nonisolated static func current() -> String {
        if let hardwareOverview = loadHardwareOverview() {
            let machineName = hardwareOverview.machineName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let rawMachineModel = hardwareOverview.machineModel?.trimmingCharacters(in: .whitespacesAndNewlines)
            let machineModel = rawMachineModel.map(formatMachineModelIdentifier)
            
            let chipName = normalizeChipName(
                hardwareOverview.chipType ?? sysctlString("machdep.cpu.brand_string")
            )
            
            let modelSize = rawMachineModel.flatMap(macBookSizeLabel(for:))
            
            if let machineName, !machineName.isEmpty, let chipName, !chipName.isEmpty {
                let deviceName: String
                
                if let modelSize, !modelSize.isEmpty {
                    deviceName = "\(machineName) \(modelSize) \(chipName)"
                } else {
                    deviceName = "\(machineName) \(chipName)"
                }
                
                if let machineModel, !machineModel.isEmpty {
                    return "\(deviceName) (\(machineModel))"
                }
                
                return deviceName
            }
        }
        
        if let processorName = sysctlString("machdep.cpu.brand_string") {
            return processorName
        }
        
        if let processorName = sysctlString("hw.model") {
            return formatMachineModelIdentifier(processorName)
        }
        
        if let processorName = sysctlString("hw.machine") {
            return processorName
        }
        
        return String(localized: "Unknown processor")
    }
    
    private nonisolated static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 1 else { return nil }
        
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        
        let value = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
    
    private nonisolated static func loadHardwareOverview() -> HardwareOverview? {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/sbin/system_profiler")
        process.arguments = ["SPHardwareDataType", "-json"]
        
        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        
        guard process.terminationStatus == 0 else { return nil }
        
        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let rows = object["SPHardwareDataType"] as? [[String: Any]],
            let first = rows.first
        else {
            return nil
        }
        
        return HardwareOverview(
            machineName: first["machine_name"] as? String,
            chipType: first["chip_type"] as? String ?? first["cpu_type"] as? String,
            machineModel: first["machine_model"] as? String
        )
    }
    
    private nonisolated static func normalizeChipName(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        
        if value.hasPrefix("Apple ") {
            return String(value.dropFirst("Apple ".count))
        }
        
        return value
    }
    
    private nonisolated static func formatMachineModelIdentifier(_ rawValue: String) -> String {
        guard let firstDigitIndex = rawValue.firstIndex(where: \.isNumber) else { return rawValue }
        let prefix = rawValue[..<firstDigitIndex]
        let suffix = rawValue[firstDigitIndex...]
        return "\(prefix) \(suffix)"
    }
    
    private nonisolated static func macBookSizeLabel(for machineModel: String) -> String? {
        switch machineModel {
        case "Mac15,3", "Mac15,4", "Mac15,5", "Mac15,6", "Mac15,7", "Mac15,8", "Mac15,9", "Mac16,3", "Mac16,5": "16"
        case "Mac14,5", "Mac14,9", "Mac14,10", "Mac15,10", "Mac16,1", "Mac16,2", "Mac16,4": "14"
        case "Mac14,2", "Mac14,15", "Mac15,12", "Mac15,13": "13"
        default: nil
        }
    }
    
    private struct HardwareOverview {
        let machineName: String?
        let chipType: String?
        let machineModel: String?
    }
}
