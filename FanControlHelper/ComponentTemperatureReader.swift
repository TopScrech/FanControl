import Foundation
import MachO
import Security

actor ComponentTemperatureReader {
    private var pending: Task<String, Error>?
    private var cached: String?
    private var sampledAt = ContinuousClock.now

    func read() async throws -> String {
        if let cached, sampledAt.duration(to: .now) < .seconds(2) { return cached }
        if let pending { return try await pending.value }
        let task = Task { try await Self.sample() }
        pending = task
        defer { pending = nil }
        let result = try await task.value
        cached = result
        sampledAt = .now
        return result
    }

    nonisolated private static func sample() async throws -> String {
        // launchd can supply a relative argv[0] for BundleProgram jobs
        // Resolve the running Mach-O image rather than trusting that argument
        var pathSize: UInt32 = 0
        _ = _NSGetExecutablePath(nil, &pathSize)
        var pathBuffer = [CChar](repeating: 0, count: Int(pathSize))
        guard _NSGetExecutablePath(&pathBuffer, &pathSize) == 0 else {
            throw failure("Could not locate the running helper")
        }
        let path = String(decoding: pathBuffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
        let executable = URL(filePath: path).resolvingSymlinksInPath()
            .deletingLastPathComponent().appending(path: "iSMC")
        var code: SecStaticCode?
        var requirement: SecRequirement?
        let rule = "anchor apple generic and certificate leaf[subject.OU] = \"8FQUA2F388\" and identifier \"dev.topscrech.FanControl.ismc\""
        guard SecStaticCodeCreateWithPath(executable as CFURL, [], &code) == errSecSuccess,
              SecRequirementCreateWithString(rule as CFString, [], &requirement) == errSecSuccess,
              let code, let requirement,
              SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate), requirement) == errSecSuccess else {
            throw failure("The component's temperature reader has an invalid signature")
        }
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let outputURL = directory.appending(path: "output")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        let output = try FileHandle(forWritingTo: outputURL)
        defer { try? output.close() }
        let process = Process()
        process.executableURL = executable
        process.arguments = ["temp"]
        process.environment = ["PATH": "/usr/bin:/bin", "LANG": "en_US.UTF-8"]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = output
        process.standardError = output
        try process.run()
        defer {
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
        }
        let deadline = ContinuousClock.now.advanced(by: .seconds(3))
        while process.isRunning {
            let size = try FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? NSNumber
            guard (size?.intValue ?? 0) < 2_000_000 else {
                throw failure("Temperature output is too large")
            }
            if ContinuousClock.now >= deadline || Task.isCancelled {
                process.terminate()
                try? await Task.sleep(for: .milliseconds(100))
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                throw failure("Temperature reader timed out")
            }
            try await Task.sleep(for: .milliseconds(50))
        }
        let attributes = try FileManager.default.attributesOfItem(atPath: outputURL.path)
        guard (attributes[.size] as? NSNumber)?.intValue ?? 0 < 2_000_000 else {
            throw failure("Temperature output is too large")
        }
        let data = try Data(contentsOf: outputURL)
        guard process.terminationStatus == 0 else { throw failure("Temperature reader failed") }
        return String(decoding: data, as: UTF8.self)
    }

    nonisolated private static func failure(_ description: String) -> NSError {
        NSError(domain: "FanControlComponent", code: 2, userInfo: [NSLocalizedDescriptionKey: description])
    }
}
