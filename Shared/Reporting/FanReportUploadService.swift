import CryptoKit
import Foundation
import IOKit

enum FanReportUploadError: Error {
    case missingDeviceIdentifier
}

struct FanReportUploadService {
    private static let reportURL = URL(string: "https://fancontrol.dev/api/report")
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func submit(report: String) async throws {
        guard let hash = Self.reportHash() else {
            throw FanReportUploadError.missingDeviceIdentifier
        }
        
        try await submit(hash: hash, report: report)
    }
    
    func submit(hash: String, report: String) async throws {
        guard let reportURL = Self.reportURL else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: reportURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            FanReportUploadRequestBody(
                hash: hash,
                report: report
            )
        )
        
        let (_, response) = try await session.data(for: request)
        
        guard
            let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
    }
    
    nonisolated private static func reportHash() -> String? {
        guard let deviceIdentifier = deviceIdentifier() else {
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
    
    nonisolated private static func deviceIdentifier() -> String? {
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        
        guard entry != 0 else { return nil }
        defer { IOObjectRelease(entry) }
        
        guard
            let uuidValue = IORegistryEntryCreateCFProperty(
                entry, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? String
        else {
            return nil
        }
        
        let uuid = uuidValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return uuid.isEmpty ? nil : uuid
    }
}

private struct FanReportUploadRequestBody: Encodable {
    let hash: String
    let report: String
}
