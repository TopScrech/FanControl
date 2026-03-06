import Foundation
import IOKit

enum MacDeviceIdentityProvider {
    nonisolated static func deviceName() -> String {
        if let localizedName = Host.current().localizedName?.trimmingCharacters(in: .whitespacesAndNewlines), !localizedName.isEmpty {
            return localizedName
        }

        let hostName = ProcessInfo.processInfo.hostName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !hostName.isEmpty {
            return hostName
        }

        return "Mac"
    }

    nonisolated static func osVersion() -> String {
        ProcessInfo.processInfo.operatingSystemVersionString
            .replacing("Version ", with: "macOS ")
            .replacing("(Build ", with: "(")
    }

    nonisolated static func deviceIdentifier() -> String? {
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        guard entry != 0 else { return nil }
        defer { IOObjectRelease(entry) }

        guard let uuidValue = IORegistryEntryCreateCFProperty(
            entry,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String
        else {
            return nil
        }

        let uuid = uuidValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return uuid.isEmpty ? nil : uuid
    }
}
