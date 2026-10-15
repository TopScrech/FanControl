import Foundation

struct LicenseActivationRequest {
    let email: String
    let licenseKey: String

    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "fancontrol",
              components.host?.lowercased() == "activate",
              components.path.isEmpty || components.path == "/",
              components.user == nil,
              components.password == nil,
              components.port == nil,
              components.fragment == nil else { return nil }

        let queryItems = components.queryItems ?? []
        let emailItems = queryItems.filter { $0.name == "email" }
        let licenseItems = queryItems.filter { $0.name == "licenseKey" }

        guard emailItems.count == 1,
              licenseItems.count == 1,
              let email = emailItems.first?.value?.trimmingCharacters(in: .whitespacesAndNewlines),
              let licenseKey = licenseItems.first?.value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty, email.count <= 320, email.contains("@"),
              !licenseKey.isEmpty, licenseKey.count <= 128 else { return nil }

        self.email = email
        self.licenseKey = licenseKey
    }
}
