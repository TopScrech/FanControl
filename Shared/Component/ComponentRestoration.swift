import Foundation

nonisolated enum ComponentRestoration {
    @MainActor
    static func confirm(
        attempts: Int = 4,
        restore: () async throws -> Void,
        pause: () async throws -> Void = { try await Task.sleep(for: .milliseconds(500)) }
    ) async throws {
        for attempt in 0..<max(1, attempts) {
            try Task.checkCancellation()
            do {
                try await restore()
                return
            } catch {
                let failure = error as NSError
                guard attempt + 1 < attempts,
                      failure.domain == NSCocoaErrorDomain,
                      [NSXPCConnectionInterrupted, NSXPCConnectionInvalid].contains(failure.code) else {
                    throw error
                }
                try await pause()
            }
        }
    }
}
