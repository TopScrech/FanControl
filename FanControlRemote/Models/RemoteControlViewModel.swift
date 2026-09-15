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
    private let isDemo: Bool

    init() {
        isDemo = false
    }

    private init(demoMac: RemoteMacState) {
        isDemo = true
        macs = [demoMac]
    }

    static func demo() -> RemoteControlViewModel {
        RemoteControlViewModel(demoMac: .demoMacBookPro)
    }

    func observe() async {
        guard !isDemo else { return }

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
        guard !isDemo else { return }

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

        if isDemo {
            await sendDemo(action: action, fanID: fanID, to: mac)
            return
        }

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

    private func sendDemo(action: RemoteFanAction, fanID: Int, to mac: RemoteMacState) async {
        let command = RemoteFanCommand(
            id: UUID().uuidString,
            deviceID: mac.id,
            fanID: fanID,
            action: action,
            createdAt: .now,
            status: .pending,
            errorMessage: nil
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            pendingCommand = command
        }

        do {
            try await Task.sleep(for: .milliseconds(350))
        } catch {
            clearPendingCommand()
            return
        }

        let updatedFans = mac.fans.map {
            guard fanID == RemoteFanCommand.allFansID || $0.id == fanID else { return $0 }

            let rpm = switch action {
            case .automatic:
                $0.minRPM + (($0.maxRPM - $0.minRPM) * 0.2)
            case .minimum:
                $0.minRPM
            case .maximum:
                $0.maxRPM
            }

            return RemoteFanState(
                id: $0.id,
                minRPM: $0.minRPM,
                maxRPM: $0.maxRPM,
                currentRPM: rpm,
                targetRPM: rpm,
                mode: action == .automatic ? 0 : 1,
                activeAction: action
            )
        }

        let updatedMac = RemoteMacState(
            id: mac.id,
            name: mac.name,
            updatedAt: .now,
            fans: updatedFans
        )

        withAnimation(.easeInOut(duration: 0.2)) {
            macs = macs.map { $0.id == mac.id ? updatedMac : $0 }
            pendingCommand = nil
        }
    }
}
