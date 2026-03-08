struct LicenseVerificationResponse: Decodable {
    let valid: Bool
    let reason: LicenseVerificationReason
    let message: String
    let status: String?
    let devicesAllowed: Int?
    let devicesRegistered: Int?
}
