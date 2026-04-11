import Foundation

struct FanSupportReportService {
    private nonisolated static let safeTemperatureRange = 10.0...110.0
    private nonisolated static let temperatureReadAttempts = 3
    private nonisolated static let retryInterval: Duration = .milliseconds(400)
    
    nonisolated func makeReport() async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let deviceDescription = MacDeviceDescriptionProvider.current()
            let appVersion = AppBundleLocator.current.versionTag
            let ismcExecutableURL = try Self.iSMCExecutableURL()
            let ismcVersion = try Self.run(executableURL: ismcExecutableURL, arguments: ["version"])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let smcExecutableURL = try Self.smcExecutableURL()
            let smcOutput = try Self.readSMCTemperatureSnapshot(executableURL: smcExecutableURL)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let temperatureSnapshot = try await Self.readStableTemperatureSnapshot(executableURL: ismcExecutableURL)
            let temperatureOutput = temperatureSnapshot.output
            let temperatureStatus = temperatureSnapshot.status
            
            return """

\(deviceDescription)
FanControl \(appVersion)
\(ismcVersion)
\(temperatureStatus)

\(temperatureOutput)

\(smcOutput)
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
    
    nonisolated private static func smcExecutableURL() throws -> URL {
        for candidate in smcCandidateExecutableURLs() {
            if FileManager.default.isExecutableFile(atPath: candidate.path()) {
                return candidate
            }
        }
        
        if let executableURL = try whichExecutableURL(named: "smc") {
            return executableURL
        }
        
        throw FanSupportReportServiceError.executableNotFound("smc")
    }
    
    nonisolated private static func candidateExecutableURLs() -> [URL] {
        var candidates = [URL]()
        let environment = ProcessInfo.processInfo.environment
        
        if let ismcPath = environment["ISMC_PATH"], !ismcPath.isEmpty {
            candidates.append(URL(filePath: ismcPath))
        }
        
        let bundle = AppBundleLocator.current
        
        if let resourceURL = bundle.resourceURL {
            candidates.append(resourceURL.appending(path: "iSMC"))
        }
        
        candidates.append(bundle.bundleURL.appending(path: "Contents/Resources/iSMC"))
        candidates.append(bundle.bundleURL.appending(path: "Contents/Library/PrivilegedHelperTools/iSMC"))
        candidates.append(URL(filePath: "/opt/homebrew/bin/iSMC"))
        candidates.append(URL(filePath: "/usr/local/bin/iSMC"))
        
        return uniqueURLs(candidates)
    }
    
    nonisolated private static func smcCandidateExecutableURLs() -> [URL] {
        var candidates = [URL]()
        let environment = ProcessInfo.processInfo.environment
        
        if let smcPath = environment["SMC_PATH"], !smcPath.isEmpty {
            candidates.append(URL(filePath: smcPath))
        }
        
        let bundle = AppBundleLocator.current
        
        if let resourceURL = bundle.resourceURL {
            candidates.append(resourceURL.appending(path: "smc"))
        }
        
        candidates.append(bundle.bundleURL.appending(path: "Contents/Resources/smc"))
        candidates.append(bundle.bundleURL.appending(path: "Contents/Library/PrivilegedHelperTools/smc"))
        candidates.append(URL(filePath: "/opt/homebrew/bin/smc"))
        candidates.append(URL(filePath: "/usr/local/bin/smc"))
        
        return uniqueURLs(candidates)
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
    
    nonisolated private static func run(executableURL: URL, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        
        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError
        
        try process.run()
        process.waitUntilExit()
        
        let output = String(
            decoding: standardOutput.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )
        
        let errorOutput = String(
            decoding: standardError.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )
        
        guard process.terminationStatus == 0 else {
            let message = errorOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            let fallbackMessage = output.trimmingCharacters(in: .whitespacesAndNewlines)
            throw FanSupportReportServiceError.commandFailed(message.isEmpty ? fallbackMessage : message)
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
    
    nonisolated private static func readSMCTemperatureSnapshot(executableURL: URL) throws -> String {
        let command = "\(shellQuoted(executableURL.path(percentEncoded: false))) -l | egrep '[[:space:]]+Tp'"
        
        return try run(executableURL: URL(filePath: "/bin/sh"), arguments: ["-lc", command])
    }
    
    nonisolated private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacing("'", with: "'\\''"))'"
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
}
