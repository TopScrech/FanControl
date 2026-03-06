import Foundation

enum ISMCExecutableLocator {
    static func executableURL() throws -> URL {
        for candidate in candidateExecutableURLs() {
            if FileManager.default.isExecutableFile(atPath: candidate.path()) {
                return candidate
            }
        }
        
        if let executableURL = try whichExecutableURL() {
            return executableURL
        }
        
        throw ISMCCommandError.executableNotFound
    }
    
    private static func candidateExecutableURLs() -> [URL] {
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
    
    private static func bundledExecutableURLs() -> [URL] {
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
        
        let bundleURL = Bundle.main.bundleURL
        
        if bundleURL.pathExtension == "app" {
            candidates.append(bundleURL.appending(path: "Contents/Resources/iSMC"))
            candidates.append(bundleURL.appending(path: "Contents/Library/PrivilegedHelperTools/iSMC"))
        }
        
        return candidates
    }
    
    private static func uniqueURLs(_ urls: [URL]) -> [URL] {
        var seenPaths = Set<String>()
        
        return urls.filter {
            seenPaths.insert($0.path()).inserted
        }
    }
    
    private static func whichExecutableURL() throws -> URL? {
        let output = try run(executableURL: URL(filePath: "/usr/bin/which"), arguments: ["iSMC"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !output.isEmpty else {
            return nil
        }
        
        return URL(filePath: output)
    }
    
    private static func goEnvironmentPath() throws -> String {
        try run(executableURL: URL(filePath: "/usr/bin/env"), arguments: ["go", "env", "GOPATH"])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func run(executableURL: URL, arguments: [String]) throws -> String {
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
            throw ISMCCommandError.commandFailed(
                errorOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        
        return output
    }
}
