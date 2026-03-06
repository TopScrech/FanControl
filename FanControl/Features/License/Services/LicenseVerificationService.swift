import Foundation

struct LicenseVerificationService {
    private static let verifyURL = URL(string: "https://fancontrol.dev/api/license/verify")
    private static let removeDeviceURL = URL(string: "https://fancontrol.dev/api/license/device/remove")
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func verify(
        email: String,
        licenseKey: String,
        deviceName: String,
        deviceIdentifier: String?,
        os: String
    ) async throws -> LicenseVerificationResponse {
        guard let verifyURL = Self.verifyURL else {
            throw LicenseVerificationServiceError.invalidResponse
        }

        var request = URLRequest(url: verifyURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = LicenseVerificationRequestBody(
            email: email,
            licenseKey: licenseKey,
            deviceName: deviceName,
            deviceIdentifier: deviceIdentifier,
            os: os
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LicenseVerificationServiceError.invalidResponse
        }

        let decoder = JSONDecoder()

        if let decodedResponse = try? decoder.decode(LicenseVerificationResponse.self, from: data) {
            return decodedResponse
        }

        throw LicenseVerificationServiceError.invalidPayload(statusCode: httpResponse.statusCode)
    }

    func removeDevice(
        email: String,
        licenseKey: String,
        deviceIdentifier: String
    ) async throws -> LicenseDeviceRemovalResponse {
        guard let removeDeviceURL = Self.removeDeviceURL else {
            throw LicenseVerificationServiceError.invalidResponse
        }

        var request = URLRequest(url: removeDeviceURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = LicenseDeviceRemovalRequestBody(
            email: email,
            licenseKey: licenseKey,
            deviceIdentifier: deviceIdentifier
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LicenseVerificationServiceError.invalidResponse
        }

        let decoder = JSONDecoder()

        if let decodedResponse = try? decoder.decode(LicenseDeviceRemovalResponse.self, from: data) {
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw LicenseVerificationServiceError.serverMessage(decodedResponse.message)
            }

            return decodedResponse
        }

        throw LicenseVerificationServiceError.invalidPayload(statusCode: httpResponse.statusCode)
    }
}
