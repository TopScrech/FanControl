import Foundation
import OSLog

@MainActor
final class AppLaunchReportSender {
    private static let logger = Logger(subsystem: "FanControl", category: "AppLaunchReportSender")
    
    private let reportService = FanSupportReportService()
    private let uploadService = FanReportUploadService()
    private var submissionTask: Task<Void, Never>?
    
    func sendIfNeeded() {
        guard submissionTask == nil else { return }
        
        submissionTask = Task {
            do {
                let report = try await reportService.makeReport()
                try await uploadService.submit(report: report)
                Self.logger.info("Submitted launch report")
            } catch FanReportUploadError.missingDeviceIdentifier {
                Self.logger.error("Skipping launch report because the device identifier is unavailable")
            } catch {
                Self.logger.error("Failed to submit launch report: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
