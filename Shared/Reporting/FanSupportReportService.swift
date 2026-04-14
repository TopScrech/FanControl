import Foundation
import IOKit

struct FanSupportReportService {
    private nonisolated static let safeTemperatureRange = 10.0...110.0
    private nonisolated static let temperatureReadAttempts = 3
    private nonisolated static let retryInterval: Duration = .milliseconds(400)
    private static let reportDateFormatter = ISO8601DateFormatter()
    
    nonisolated func makeReport() async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let deviceDescription = MacDeviceDescriptionProvider.current()
            let cpuCoresDescription = MacDeviceDescriptionProvider.cpuCoresDescription() ?? "Unavailable"
            let deviceIdentifier = Self.deviceIdentifier() ?? "Unavailable"
            let appVersion = AppBundleLocator.current.versionTag
            let reportDate = Self.reportDateFormatter.string(from: .now)
            let ismcExecutableURL = try Self.iSMCExecutableURL()
            let ismcVersion = try Self.run(executableURL: ismcExecutableURL, arguments: ["version"])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let rawOutput = try Self.readRawSnapshot(executableURL: ismcExecutableURL)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let temperatureSnapshot = try await Self.readStableTemperatureSnapshot(executableURL: ismcExecutableURL)
            let temperatureOutput = temperatureSnapshot.output
            let temperatureStatus = temperatureSnapshot.status
            
            return """

\(deviceDescription)
CPU Cores: \(cpuCoresDescription)
Device ID: \(deviceIdentifier)
Report Date: \(reportDate)
FanControl \(appVersion)
\(ismcVersion)

\(temperatureStatus)
\(temperatureOutput)

\(rawOutput)
"""
        }.value
    }
    
    nonisolated private static func iSMCExecutableURL() throws -> URL {
        for candidate in candidateExecutableURLs() {
            if FileManager.default.isExecutableFile(atPath: candidate.path()) {
                return candidate
            }
        }
        
        if let executableURL = try whichExecutableURL(named: "iSMC") {
            return executableURL
        }
        
        throw FanSupportReportServiceError.executableNotFound("iSMC")
    }
    
    nonisolated private static func candidateExecutableURLs() -> [URL] {
        var candidates = [URL]()
        let environment = ProcessInfo.processInfo.environment
        
        if let ismcPath = environment["ISMC_PATH"], !ismcPath.isEmpty {
            candidates.append(URL(filePath: ismcPath))
        }
        
        candidates.append(contentsOf: bundledExecutableURLs())
        
        if let goPath = environment["GOPATH"], !goPath.isEmpty {
            candidates.append(URL(filePath: goPath).appending(path: "bin/iSMC"))
        }
        
        candidates.append(URL.homeDirectory.appending(path: "go/bin/iSMC"))
        candidates.append(URL(filePath: "/opt/homebrew/bin/iSMC"))
        candidates.append(URL(filePath: "/usr/local/bin/iSMC"))
        
        if let goPath = try? goEnvironmentPath(), !goPath.isEmpty {
            candidates.append(URL(filePath: goPath).appending(path: "bin/iSMC"))
        }
        
        return uniqueURLs(candidates)
    }
    
    nonisolated private static func bundledExecutableURLs() -> [URL] {
        var candidates = [URL]()
        
        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL.appending(path: "iSMC"))
        }
        
        if let executableURL = Bundle.main.executableURL {
            var directoryURL = executableURL.deletingLastPathComponent()
            
            for _ in 0..<4 {
                candidates.append(directoryURL.appending(path: "iSMC"))
                candidates.append(directoryURL.appending(path: "Resources/iSMC"))
                candidates.append(directoryURL.appending(path: "Library/PrivilegedHelperTools/iSMC"))
                directoryURL.deleteLastPathComponent()
            }
        }
        
        let bundleURL = AppBundleLocator.current.bundleURL
        
        if bundleURL.pathExtension == "app" {
            candidates.append(bundleURL.appending(path: "Contents/Resources/iSMC"))
            candidates.append(bundleURL.appending(path: "Contents/Library/PrivilegedHelperTools/iSMC"))
        }
        
        return candidates
    }
    
    nonisolated private static func uniqueURLs(_ urls: [URL]) -> [URL] {
        var seenPaths = Set<String>()
        
        return urls.filter {
            seenPaths.insert($0.path()).inserted
        }
    }
    
    nonisolated private static func whichExecutableURL(named executableName: String) throws -> URL? {
        let output = try run(executableURL: URL(filePath: "/usr/bin/which"), arguments: [executableName])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !output.isEmpty else {
            return nil
        }
        
        return URL(filePath: output)
    }
    
    nonisolated private static func goEnvironmentPath() throws -> String {
        try run(executableURL: URL(filePath: "/usr/bin/env"), arguments: ["go", "env", "GOPATH"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    nonisolated private static func run(executableURL: URL, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        
        try process.run()
        
        let output = String(
            decoding: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )
        
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw FanSupportReportServiceError.commandFailed(
                output.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        
        return output
    }
    
    nonisolated private static func readStableTemperatureSnapshot(executableURL: URL) async throws -> (output: String, status: String) {
        var latestSnapshot: (output: String, status: String)?
        
        for attempt in 1...temperatureReadAttempts {
            let output = try run(executableURL: executableURL, arguments: ["temp"])
                .trimmingCharacters(in: .newlines)
            let status = temperatureStatus(from: output)
            let snapshot = (output, status)
            latestSnapshot = snapshot
            
            if status == "✅ All values within the 10-110 range" || attempt == temperatureReadAttempts {
                return snapshot
            }
            
            try await Task.sleep(for: retryInterval)
        }
        
        guard let latestSnapshot else {
            throw FanSupportReportServiceError.commandFailed("Temperature output unavailable")
        }
        
        return latestSnapshot
    }
    
    nonisolated private static func readRawSnapshot(executableURL: URL) throws -> String {
        try run(executableURL: executableURL, arguments: ["raw"])
    }
    
    nonisolated private static func temperatureStatus(from output: String) -> String {
        let temperatures = output
            .split(whereSeparator: \.isNewline)
            .compactMap(temperatureValue(from:))
        
        guard !temperatures.isEmpty else {
            return "⚠️ Extreme values detected"
        }
        
        let hasExtremeValues = temperatures.contains {
            !safeTemperatureRange.contains($0)
        }
        
        if hasExtremeValues {
            return "⚠️ Extreme values detected"
        }
        
        return "✅ All values within the 10-110 range"
    }
    
    nonisolated private static func temperatureValue(from rawLine: Substring) -> Double? {
        let temperaturePattern = #/(-?\d+(?:[.,]\d+)?)\s*°C/#
        
        guard let match = rawLine.firstMatch(of: temperaturePattern) else {
            return nil
        }
        
        return Double(String(match.output.1).replacing(",", with: "."))
    }

    nonisolated private static func deviceIdentifier() -> String? {
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))

        guard entry != 0 else { return nil }
        defer { IOObjectRelease(entry) }

        guard
            let uuidValue = IORegistryEntryCreateCFProperty(
                entry, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? String
        else {
            return nil
        }

        let uuid = uuidValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return uuid.isEmpty ? nil : uuid
    }
}
