import OSLog
import SwiftUI

@Observable
final class RemoteControlViewModel {
    var macs: [RemoteMacState] = []
    var isRefreshing = false
    var pendingCommand: RemoteFanCommand?

    private static let refreshInterval: Duration = .seconds(1)
    private static let logger = Logger(subsystem: "FanControlRemote", category: "Discovery")
    private let store = RemoteCloudStore()

    func observe() async {
        while !Task.isCancelled {
            await refresh()

            do {
                try await Task.sleep(for: Self.refreshInterval)
            } catch {
                return
            }
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let refreshedMacs = try await store.fetchMacs()
            
            withAnimation(.easeInOut(duration: 0.2)) {
                macs = refreshedMacs
            }
        } catch {
            Self.logger.error("Mac discovery failed: \(error)")
            return
        }
    }

    func send(action: RemoteFanAction, fanID: Int, to mac: RemoteMacState) async {
        guard pendingCommand == nil else { return }

        do {
            let command = try await store.sendCommand(deviceID: mac.id, fanID: fanID, action: action)
            
            withAnimation(.easeInOut(duration: 0.2)) {
                pendingCommand = command
            }
            
            try await waitForCommandResult(deviceID: mac.id)
        } catch {
            clearPendingCommand()
        }
    }

    func mac(withID id: String) -> RemoteMacState? {
        macs.first {
            $0.id == id
        }
    }

    func activeAction(fanID: Int, in mac: RemoteMacState) -> RemoteFanAction? {
        let targetFans = fanID == RemoteFanCommand.allFansID
            ? mac.fans
            : mac.fans.filter { $0.id == fanID }
        guard let firstAction = targetFans.first?.activeAction else { return nil }
        guard targetFans.allSatisfy({ $0.activeAction == firstAction }) else { return nil }
        return firstAction
    }

    func hasPendingCommand(for deviceID: String) -> Bool {
        pendingCommand?.deviceID == deviceID
    }

    private func waitForCommandResult(deviceID: String) async throws {
        for _ in 0..<25 {
            try await Task.sleep(for: .seconds(1))
            guard let result = try await store.fetchCommand(deviceID: deviceID) else { continue }
            guard result.id == pendingCommand?.id else { continue }

            switch result.status {
            case .pending:
                continue
            case .completed:
                await refresh()
                clearPendingCommand()
                return
            case .failed:
                clearPendingCommand()
                throw RemoteCommandFailureError(message: result.errorMessage)
            }
        }

        clearPendingCommand()
        throw RemoteCommandFailureError(message: String(localized: "The Mac did not respond in time"))
    }
    
    private func clearPendingCommand() {
        withAnimation(.easeInOut(duration: 0.2)) {
            pendingCommand = nil
        }
    }
}
