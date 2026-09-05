import Foundation

nonisolated enum ComponentInstallPhase: String {
    case unavailable, installing, waitingForApproval, connecting, ready, failed
}
