import SwiftUI

final class AppTerminationDelegate: NSObject, NSApplicationDelegate {
    private static let terminationGracePeriod: Duration = .seconds(3)
    
    var onTerminate: (@MainActor () async -> Void)?
    
    private var isHandlingTermination = false
    private var terminationTask: Task<Void, Never>?
    private var terminationTimeoutTask: Task<Void, Never>?
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isHandlingTermination else { return .terminateNow }
        
        guard let onTerminate else {
            return .terminateNow
        }
        
        isHandlingTermination = true
        
        let finishTermination: @MainActor () -> Void = { [weak self] in
            guard let self, self.isHandlingTermination else { return }
            
            self.terminationTask?.cancel()
            self.terminationTimeoutTask?.cancel()
            self.terminationTask = nil
            self.terminationTimeoutTask = nil
            self.isHandlingTermination = false
            sender.reply(toApplicationShouldTerminate: true)
        }
        
        terminationTask = Task { @MainActor in
            await onTerminate()
            finishTermination()
        }
        
        terminationTimeoutTask = Task { @MainActor in
            try? await Task.sleep(for: Self.terminationGracePeriod)
            finishTermination()
        }
        
        return .terminateLater
    }
}
