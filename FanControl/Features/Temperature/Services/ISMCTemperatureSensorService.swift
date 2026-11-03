import Foundation

actor ISMCTemperatureSensorService {
    private var cachedExecutableURL: URL?

    func readTemperatureSensors() async throws -> [TemperatureSensor] {
        let cachedURL = cachedExecutableURL
        let (executableURL, sensors) = try await Task.detached(priority: .userInitiated) {
            let executableURL: URL
            if let cachedURL, FileManager.default.isExecutableFile(atPath: cachedURL.path()) {
                executableURL = cachedURL
            } else {
                executableURL = try ISMCExecutableLocator.executableURL()
            }
            let output = try Self.run(executableURL: executableURL, arguments: ["temp"])
            return (executableURL, try ISMCTemperatureSensorParser.parse(output))
        }.value
        cachedExecutableURL = executableURL
        return sensors
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
            throw ISMCCommandError.commandFailed(message.isEmpty ? output : message)
        }
        
        return output
    }
}
