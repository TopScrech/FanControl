import Foundation
import CoreGraphics

enum MacDeviceDescriptionProvider {
    nonisolated static func current() -> String {
        if let hardwareOverview = loadHardwareOverview() {
            let machineName = hardwareOverview.machineName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let rawMachineModel = hardwareOverview.machineModel?.trimmingCharacters(in: .whitespacesAndNewlines)
            let machineModel = rawMachineModel.map(formatMachineModelIdentifier)
            
            let chipName = normalizeChipName(
                hardwareOverview.chipType ?? sysctlString("machdep.cpu.brand_string")
            )
            
            let modelSize = builtInDisplaySizeLabel()
            
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
    
    nonisolated static func cpuCoresDescription() -> String? {
        guard let hardwareOverview = loadHardwareOverview() else { return nil }
        return formatCPUCores(hardwareOverview.numberProcessors)
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
            machineModel: first["machine_model"] as? String,
            numberProcessors: first["number_processors"] as? String
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
    
    private nonisolated static func builtInDisplaySizeLabel() -> String? {
        let maxDisplayCount: UInt32 = 16
        var activeDisplayCount: UInt32 = 0
        var activeDisplayIDs = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplayCount))
        
        guard CGGetActiveDisplayList(maxDisplayCount, &activeDisplayIDs, &activeDisplayCount) == .success else {
            return nil
        }
        
        for displayID in activeDisplayIDs.prefix(Int(activeDisplayCount)) where CGDisplayIsBuiltin(displayID) != 0 {
            let sizeInMillimeters = CGDisplayScreenSize(displayID)
            guard sizeInMillimeters.width > 0, sizeInMillimeters.height > 0 else { continue }
            
            let diagonalInMillimeters = hypot(sizeInMillimeters.width, sizeInMillimeters.height)
            let diagonalInInches = diagonalInMillimeters / 25.4
            let roundedSize = Int(diagonalInInches.rounded())
            
            guard roundedSize > 0 else { continue }
            return String(roundedSize)
        }
        
        return nil
    }
    
    private nonisolated static func formatCPUCores(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }
        
        let components = rawValue.split(separator: ":")
        guard components.count >= 3 else {
            let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }
        
        let totalValue = components[0].replacing("proc ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let performanceValue = String(components[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        let efficiencyValue = String(components[2]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard
            !totalValue.isEmpty,
            !performanceValue.isEmpty,
            !efficiencyValue.isEmpty
        else {
            return nil
        }
        
        return "\(totalValue) (\(performanceValue) Performance and \(efficiencyValue) Efficiency)"
    }
    
    private struct HardwareOverview {
        let machineName: String?
        let chipType: String?
        let machineModel: String?
        let numberProcessors: String?
    }
}
