//import Darwin
import Foundation

@main
enum FanCommandMain {
    static func main() async {
        do {
            let command = try FanCommandParser.parse(arguments: Array(CommandLine.arguments.dropFirst()))
            try await FanCLI().run(command)
        } catch let error as FanCLIError {
            writeStandardError(error.message)
            exit(error.exitCode)
        } catch {
            writeStandardError(error.localizedDescription)
            exit(1)
        }
    }
    
    private static func writeStandardError(_ message: String) {
        guard let data = "\(message)\n".data(using: .utf8) else { return }
        FileHandle.standardError.write(data)
    }
}
