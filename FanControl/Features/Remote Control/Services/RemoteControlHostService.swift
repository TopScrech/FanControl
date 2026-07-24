import Foundation
import OSLog

@MainActor
final class RemoteControlHostService {
    typealias FanProvider = @MainActor () -> [RemoteFanState]
    typealias CommandHandler = @MainActor (RemoteFanCommand) async throws -> Void
    typealias StatusHandler = @MainActor (String) -> Void
    
    private static let refreshInterval: Duration = .seconds(3)
    private static let logger = Logger(subsystem: "FanControl", category: "RemoteControl")
    
    private let store = RemoteCloudStore()
    private var task: Task<Void, Never>?
    
    deinit {
        task?.cancel()
    }
    
    func start(
        deviceID: String,
        name: String,
        fans: @escaping FanProvider,
        handleCommand: @escaping CommandHandler,
        updateStatus: @escaping StatusHandler
    ) {
        stop()
        updateStatus(String(localized: "Connecting to iCloud"))
        let store = store
        
        task = Task {
            var lastHandledCommandID: String?
            
            while !Task.isCancelled {
                do {
                    try await store.publishMac(deviceID: deviceID, name: name, fans: fans())
                    Self.logger.info("Published remote Mac id=\(deviceID, privacy: .private(mask: .hash))")
                    
                    if
                        let command = try await store.fetchCommand(deviceID: deviceID),
                        command.status == .pending,
                        command.id != lastHandledCommandID
                            {
                        lastHandledCommandID = command.id
                        
                        if command.isExpired {
                            try await store.completeCommand(
                                command,
                                errorMessage: String(localized: "Command expired")
                            )
                        } else {
                            do {
                                try await handleCommand(command)
                                
                                do {
                                    try await store.publishMac(
                                        deviceID: deviceID,
                                        name: name,
                                        fans: fans()
                                    )
                                } catch {
                                    Self.logger.error("Post-command publish failed: \(error)")
                                }
                                
                                try await store.completeCommand(command, errorMessage: nil)
                            } catch {
                                try await store.completeCommand(command, errorMessage: error.localizedDescription)
                            }
                        }
                    }
                    
                    updateStatus(String(localized: "Available remotely"))
                } catch is CancellationError {
                    return
                } catch {
                    updateStatus(error.localizedDescription)
                    Self.logger.error("Remote control update failed: \(error)")
                }
                
                do {
                    try await Task.sleep(for: Self.refreshInterval)
                } catch {
                    return
                }
            }
        }
    }
    
    func stop() {
        task?.cancel()
        task = nil
    }
}
