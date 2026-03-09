struct LicenseDeviceRemovalRequestBody: Encodable {
    let email: String
    let licenseKey: String
    let deviceIdentifier: String
}
