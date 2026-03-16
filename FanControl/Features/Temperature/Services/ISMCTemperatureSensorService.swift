import Foundation

struct ISMCTemperatureSensorService {
    nonisolated func readTemperatureSensors() async throws -> [TemperatureSensor] {
        try await Task.detached(priority: .userInitiated) {
            let executableURL = try ISMCExecutableLocator.executableURL()
            let output = try Self.run(executableURL: executableURL, arguments: ["temp"])
            return try ISMCTemperatureSensorParser.parse(output)
        }.value
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
