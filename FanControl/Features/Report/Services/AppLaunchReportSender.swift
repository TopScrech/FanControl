import CryptoKit
import Foundation
import OSLog

@MainActor
final class AppLaunchReportSender {
    private static let logger = Logger(subsystem: "FanControl", category: "AppLaunchReportSender")
    
    private let reportService = FanSupportReportService()
    private let submissionService = AppReportSubmissionService()
    private var submissionTask: Task<Void, Never>?
    
    func sendIfNeeded() {
        guard submissionTask == nil else { return }
        
        submissionTask = Task {
            do {
                guard let hash = Self.reportHash() else {
                    Self.logger.error("Skipping launch report because the device identifier is unavailable")
                    return
                }
                
                let report = try await reportService.makeReport()
                try await submissionService.submit(hash: hash, report: report)
                Self.logger.info("Submitted launch report")
            } catch {
                Self.logger.error("Failed to submit launch report: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    nonisolated private static func reportHash() -> String? {
        guard let deviceIdentifier = MacDeviceIdentityProvider.deviceIdentifier() else {
            return nil
        }
        
        let hashInput = "\(AppBundleLocator.current.appVersion)|\(deviceIdentifier)"
        let digest = SHA256.hash(data: Data(hashInput.utf8))
        
        return digest.reduce(into: "") { partialResult, byte in
            let hex = String(byte, radix: 16)
            
            if hex.count == 1 {
                partialResult.append("0")
            }
            
            partialResult.append(hex)
        }
    }
}
