import Foundation

// Block termination signals before creating worker threads so sigwait owns delivery
var terminationSignals = sigset_t()
sigemptyset(&terminationSignals)
sigaddset(&terminationSignals, SIGTERM)
sigaddset(&terminationSignals, SIGINT)
pthread_sigmask(SIG_BLOCK, &terminationSignals, nil)

let engine = MainActor.assumeIsolated { FanControlEngine() }
let delegate = FanControlHelperDelegate(engine: engine)
let listener = NSXPCListener(machServiceName: FanControlXPCConstants.machServiceName)
listener.delegate = delegate
listener.resume()

Task { @MainActor in
    while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(1))
        engine.checkLease()
    }
}

Task.detached {
    var signals = sigset_t()
    sigemptyset(&signals)
    sigaddset(&signals, SIGTERM)
    sigaddset(&signals, SIGINT)
    var received: Int32 = 0
    sigwait(&signals, &received)
    for _ in 0..<5 {
        let restored = await MainActor.run { (try? engine.prepareForUpdate()) != nil }
        if restored { break }
        try? await Task.sleep(for: .milliseconds(200))
    }
    exit(EXIT_SUCCESS)
}
RunLoop.current.run()
