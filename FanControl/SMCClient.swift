import Foundation

final class SMCClient {
    private static let serviceClasses = ["AppleSMC", "AppleSMCKeysEndpoint"]
    private static let userClientTypes: [UInt32] = [0, 1]
    
    private let connection: io_connect_t
    private let queue = DispatchQueue(label: "SMCClient.queue")
    private var platform: Platform = .appleSiliconLike
    
    init() throws {
        connection = try Self.openConnection()
        
        let fanType = (try? readKey("F0Ac").dataType.trimmingCharacters(in: .whitespaces)) ?? ""
        
        if fanType == "flt" {
            platform = .appleSiliconLike
        } else {
            platform = .intelLike
        }
    }
    
    deinit {
        IOServiceClose(connection)
    }
    
    private static func openConnection() throws -> io_connect_t {
        var lastError: kern_return_t = KERN_SUCCESS
        
        for serviceClass in serviceClasses {
            let matching = IOServiceMatching(serviceClass)
            var iterator: io_iterator_t = 0
            let matchResult = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
            
            guard matchResult == KERN_SUCCESS else {
                lastError = matchResult
                continue
            }
            
            defer { IOObjectRelease(iterator) }
            
            while true {
                let service = IOIteratorNext(iterator)
                guard service != 0 else { break }
                defer { IOObjectRelease(service) }
                
                for userClientType in userClientTypes {
                    var conn: io_connect_t = 0
                    let openResult = IOServiceOpen(service, mach_task_self_, userClientType, &conn)
                    
                    if openResult == KERN_SUCCESS {
                        return conn
                    }
                    
                    lastError = openResult
                }
            }
        }
        
        if lastError == KERN_SUCCESS {
            throw SMCError.serviceNotFound
        }
        
        throw SMCError.openFailed(lastError)
    }
    
    func readFans() throws -> [Fan] {
        try queue.sync {
            let count = Int(try readUInt8("FNum"))
            
            return try (0..<count).map { id in
                let min = try readRPM("F\(id)Mn")
                let max = try readRPM("F\(id)Mx")
                let current = try readRPM("F\(id)Ac")
                let target = try readRPM("F\(id)Tg")
                let mode = try readUInt8("F\(id)Md")
                
                return Fan(id: id, minRPM: min, maxRPM: max, currentRPM: current, targetRPM: target, mode: mode)
            }
        }
    }
    
    func setFanManualRPM(fanID: Int, rpm: Double) throws {
        try queue.sync {
            let min = try readRPM("F\(fanID)Mn")
            let max = try readRPM("F\(fanID)Mx")
            let clamped = Swift.min(Swift.max(rpm, min), max)
            
            if platform == .appleSiliconLike {
                try unlockForManualControl(fanID: fanID)
            }
            
            try writeUInt8("F\(fanID)Md", value: 1)
            try writeRPM("F\(fanID)Tg", value: clamped)
            
            if platform == .appleSiliconLike {
                try writeUInt8("Ftst", value: 1)
            }
        }
    }
    
    func setFanAuto(fanID: Int) throws {
        try queue.sync {
            try writeUInt8("F\(fanID)Md", value: 0)
            
            if platform == .appleSiliconLike {
                try writeUInt8("Ftst", value: 0)
            }
        }
    }
    
    func keepAliveManualOverride() throws {
        try queue.sync {
            guard platform == .appleSiliconLike else { return }
            try writeUInt8("Ftst", value: 1)
        }
    }
    
    private func unlockForManualControl(fanID: Int) throws {
        let modeKey = "F\(fanID)Md"
        let currentMode = try readUInt8(modeKey)
        
        guard currentMode == 3 else { return }
        
        try writeUInt8("Ftst", value: 1)
        
        let deadline = Date().addingTimeInterval(8)
        
        while Date() < deadline {
            let mode = try readUInt8(modeKey)
            if mode == 0 { break }
            usleep(200_000)
        }
    }
}

private extension SMCClient {
    static let selector: UInt32 = 2
    static let cmdReadKeyInfo: UInt8 = 9
    static let cmdReadBytes: UInt8 = 5
    static let cmdWriteBytes: UInt8 = 6
    
    func readUInt8(_ key: String) throws -> UInt8 {
        let v = try readKey(key)
        guard let b = v.bytes.first else { throw SMCError.badValue(key) }
        
        return b
    }
    
    func readRPM(_ key: String) throws -> Double {
        let v = try readKey(key)
        
        switch v.dataType.trimmingCharacters(in: .whitespaces) {
        case "fpe2":
            guard v.bytes.count >= 2 else { throw SMCError.badValue(key) }
            let raw = (UInt16(v.bytes[0]) << 8) | UInt16(v.bytes[1])
            return Double(raw) / 4.0
            
        case "flt":
            guard v.bytes.count >= 4 else { throw SMCError.badValue(key) }
            
            let raw = UInt32(v.bytes[0])
            | (UInt32(v.bytes[1]) << 8)
            | (UInt32(v.bytes[2]) << 16)
            | (UInt32(v.bytes[3]) << 24)
            
            return Double(Float(bitPattern: raw))
            
        default:
            throw SMCError.unsupportedType(v.dataType, key: key)
        }
    }
    
    func writeUInt8(_ key: String, value: UInt8) throws {
        try writeKey(key, bytes: [value])
    }
    
    func writeRPM(_ key: String, value: Double) throws {
        let info = try readKeyInfo(key)
        let dataType = fourCharString(info.dataType).trimmingCharacters(in: .whitespaces)
        
        switch dataType {
        case "fpe2":
            let raw = UInt16(max(0, min(65535, Int((value * 4.0).rounded()))))
            
            let bytes: [UInt8] = [
                UInt8((raw >> 8) & 0xFF),
                UInt8(raw & 0xFF),
            ]
            
            try writeKey(key, bytes: bytes)
            
        case "flt":
            let f = Float(value)
            let raw = f.bitPattern
            
            let bytes: [UInt8] = [
                UInt8(raw & 0xFF),
                UInt8((raw >> 8) & 0xFF),
                UInt8((raw >> 16) & 0xFF),
                UInt8((raw >> 24) & 0xFF),
            ]
            
            try writeKey(key, bytes: bytes)
            
        default:
            throw SMCError.unsupportedType(fourCharString(info.dataType), key: key)
        }
    }
    
    func readKey(_ key: String) throws -> SMCValue {
        let info = try readKeyInfo(key)
        
        var input = SMCKeyData()
        input.key = fourCharCode(key)
        input.keyInfo.dataSize = info.dataSize
        input.data8 = Self.cmdReadBytes
        
        var output = SMCKeyData()
        try callSMC(&input, &output)
        
        let dataType = fourCharString(info.dataType)
        let all = output.bytes.toArray()
        let size = Int(info.dataSize)
        
        return SMCValue(key: key, dataType: dataType, bytes: Array(all.prefix(size)))
    }
    
    func writeKey(_ key: String, bytes: [UInt8]) throws {
        let info = try readKeyInfo(key)
        let size = Int(info.dataSize)
        
        var input = SMCKeyData()
        input.key = fourCharCode(key)
        input.keyInfo.dataSize = info.dataSize
        input.data8 = Self.cmdWriteBytes
        
        var payload = bytes
        
        if payload.count < size {
            payload += Array(repeating: 0, count: size - payload.count)
        }
        
        if payload.count > 32 {
            payload = Array(payload.prefix(32))
        }
        
        input.bytes.setFromArray(payload)
        
        var output = SMCKeyData()
        try callSMC(&input, &output)
    }
    
    func readKeyInfo(_ key: String) throws -> SMCKeyDataKeyInfo {
        var input = SMCKeyData()
        input.key = fourCharCode(key)
        input.data8 = Self.cmdReadKeyInfo
        
        var output = SMCKeyData()
        try callSMC(&input, &output)
        
        return output.keyInfo
    }
    
    func callSMC(_ input: inout SMCKeyData, _ output: inout SMCKeyData) throws {
        var outSize = MemoryLayout<SMCKeyData>.stride
        let inSize = MemoryLayout<SMCKeyData>.stride
        
        let result = withUnsafePointer(to: &input) { inputPtr in
            withUnsafeMutablePointer(to: &output) { outputPtr in
                IOConnectCallStructMethod(connection, Self.selector, inputPtr, inSize, outputPtr, &outSize)
            }
        }
        
        guard result == KERN_SUCCESS else { throw SMCError.callFailed(result) }
    }
    
    func fourCharCode(_ str: String) -> UInt32 {
        var result: UInt32 = 0
        for u in str.utf8.prefix(4) {
            result = (result << 8) + UInt32(u)
        }
        return result
    }
    
    func fourCharString(_ code: UInt32) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF),
        ]
        
        return String(bytes: bytes, encoding: .ascii) ?? ""
    }
}

private struct SMCValue {
    let key: String
    let dataType: String
    let bytes: [UInt8]
}

private enum SMCError: LocalizedError {
    case serviceNotFound
    case openFailed(kern_return_t)
    case callFailed(kern_return_t)
    case badValue(String)
    case unsupportedType(String, key: String)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotFound:
            "AppleSMC service not found"
            
        case .openFailed(let code):
            "Failed to open AppleSMC (kern=\(code))"
            
        case .callFailed(let code):
            "SMC call failed (kern=\(code))"
            
        case .badValue(let key):
            "Bad SMC value for \(key)"
            
        case .unsupportedType(let type, let key):
            "Unsupported SMC type \(type) for \(key)"
        }
    }
}

private struct SMCKeyDataVers {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

private struct SMCKeyDataPLimitData {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
}

private struct SMCKeyDataKeyInfo {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
    var _padding0: UInt8 = 0
    var _padding1: UInt8 = 0
    var _padding2: UInt8 = 0
}

private struct SMCBytes32 {
    var b0: UInt8 = 0
    var b1: UInt8 = 0
    var b2: UInt8 = 0
    var b3: UInt8 = 0
    var b4: UInt8 = 0
    var b5: UInt8 = 0
    var b6: UInt8 = 0
    var b7: UInt8 = 0
    var b8: UInt8 = 0
    var b9: UInt8 = 0
    var b10: UInt8 = 0
    var b11: UInt8 = 0
    var b12: UInt8 = 0
    var b13: UInt8 = 0
    var b14: UInt8 = 0
    var b15: UInt8 = 0
    var b16: UInt8 = 0
    var b17: UInt8 = 0
    var b18: UInt8 = 0
    var b19: UInt8 = 0
    var b20: UInt8 = 0
    var b21: UInt8 = 0
    var b22: UInt8 = 0
    var b23: UInt8 = 0
    var b24: UInt8 = 0
    var b25: UInt8 = 0
    var b26: UInt8 = 0
    var b27: UInt8 = 0
    var b28: UInt8 = 0
    var b29: UInt8 = 0
    var b30: UInt8 = 0
    var b31: UInt8 = 0
    
    mutating func setFromArray(_ bytes: [UInt8]) {
        var tmp = [UInt8](repeating: 0, count: 32)
        
        for (i, b) in bytes.prefix(32).enumerated() {
            tmp[i] = b
        }
        
        withUnsafeMutableBytes(of: &self) {
            $0.copyBytes(from: tmp)
        }
    }
    
    func toArray() -> [UInt8] {
        withUnsafeBytes(of: self) { Array($0) }
    }
}

private struct SMCKeyData {
    var key: UInt32 = 0
    var vers = SMCKeyDataVers()
    var pLimitData = SMCKeyDataPLimitData()
    var keyInfo = SMCKeyDataKeyInfo()
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes = SMCBytes32()
}
