import Foundation

struct AppReportSubmissionService {
    private static let reportURL = URL(string: "https://fancontrol.dev/api/report")
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
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
            AppReportRequestBody(
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
}
