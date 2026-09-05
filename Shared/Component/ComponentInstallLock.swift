import Foundation

// An advisory lock serializes separate installer processes and releases on crashes
nonisolated final class ComponentInstallLock {
    private let descriptor: Int32

    init(directory: URL) throws {
        let url = directory.appending(path: "installation.lock")
        descriptor = open(url.path, O_CREAT | O_RDWR | O_NOFOLLOW | O_CLOEXEC, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { throw Self.failure(errno) }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            let code = errno
            throw Self.failure(code)
        }
    }

    // Swift also runs deinit when this initialized instance throws from init
    deinit { if descriptor >= 0 { close(descriptor) } }

    private static func failure(_ code: Int32) -> NSError {
        NSError(domain: NSPOSIXErrorDomain, code: Int(code), userInfo: [NSLocalizedDescriptionKey: "Another component installation is running or its lock is unavailable"])
    }
}
