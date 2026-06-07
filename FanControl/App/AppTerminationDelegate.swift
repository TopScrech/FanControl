import SwiftUI

final class AppTerminationDelegate: NSObject, NSApplicationDelegate {
    private static let terminationGracePeriod: Duration = .seconds(3)
    
    var onTerminate: (@MainActor () async -> Void)?
    var onSleep: (@MainActor () async -> Void)?
    
    private var isHandlingTermination = false
    private var terminationTask: Task<Void, Never>?
    private var terminationTimeoutTask: Task<Void, Never>?
    
    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        DockIconVisibilityController.applyStoredPreference()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
    }
    
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
    
    @objc private func workspaceWillSleep(_ notification: Notification) {
        guard let onSleep else { return }
        
        Task { @MainActor in
            await onSleep()
        }
    }
}
