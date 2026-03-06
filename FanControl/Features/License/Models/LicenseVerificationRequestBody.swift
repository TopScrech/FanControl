import Foundation

struct LicenseVerificationRequestBody: Encodable {
    let email: String
    let licenseKey: String
    let deviceName: String
    let deviceIdentifier: String?
    let os: String
}
