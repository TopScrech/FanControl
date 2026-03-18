import Foundation

struct FanReportService {
    nonisolated func makeReport() async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let deviceDescription = MacDeviceDescriptionProvider.current()
            let appVersion = AppBundleLocator.current.versionTag
            let ismcExecutableURL = try Self.iSMCExecutableURL()
            let ismcVersion = try Self.run(executableURL: ismcExecutableURL, arguments: ["version"])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let temperatureOutput = try Self.run(executableURL: ismcExecutableURL, arguments: ["temp"])
                .trimmingCharacters(in: .newlines)
            let temperatureStatus = Self.temperatureStatus(from: temperatureOutput)
            
            return """

\(deviceDescription)
FanControl \(appVersion)
\(ismcVersion)
\(temperatureStatus)

\(temperatureOutput)
"""
        }.value
    }
    
    nonisolated private static func iSMCExecutableURL() throws -> URL {
        for candidate in candidateExecutableURLs() {
            if FileManager.default.isExecutableFile(atPath: candidate.path()) {
                return candidate
            }
        }
        
        if let executableURL = try whichExecutableURL() {
            return executableURL
        }
        
        throw FanCLIError.failure("iSMC executable not found")
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
    
    nonisolated private static func uniqueURLs(_ urls: [URL]) -> [URL] {
        var seenPaths = Set<String>()
        
        return urls.filter {
            seenPaths.insert($0.path()).inserted
        }
    }
    
    nonisolated private static func whichExecutableURL() throws -> URL? {
        let output = try run(executableURL: URL(filePath: "/usr/bin/which"), arguments: ["iSMC"])
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
            throw FanCLIError.failure(message.isEmpty ? fallbackMessage : message)
        }
        
        return output
    }
    
    nonisolated private static func temperatureStatus(from output: String) -> String {
        let temperatures = output
            .split(whereSeparator: \.isNewline)
            .compactMap(temperatureValue(from:))
        
        let safeTemperatureRange = 10.0...110.0
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
