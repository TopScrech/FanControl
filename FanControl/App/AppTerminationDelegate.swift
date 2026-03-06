import AppKit

@MainActor
final class AppTerminationDelegate: NSObject, NSApplicationDelegate {
    var onTerminate: (@MainActor () async -> Void)?
    
    private var isHandlingTermination = false
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isHandlingTermination else { return .terminateLater }
        
        guard let onTerminate else {
            return .terminateNow
        }
        
        isHandlingTermination = true
        
        Task { @MainActor [weak self] in
            await onTerminate()
            sender.reply(toApplicationShouldTerminate: true)
            self?.isHandlingTermination = false
        }
        
        return .terminateLater
    }
}
