// License purchasing disabled for this distribution
// import Foundation
//
// struct LicenseCredentialStore {
//     private static let emailDefaultsKey = "licenseEmail"
//     private static let lastCheckDateDefaultsKey = "licenseLastCheckDate"
//     private static let lastCheckReasonDefaultsKey = "licenseLastCheckReason"
//     private static let lastActiveValidationDateDefaultsKey = "licenseLastActiveValidationDate"
//
//     private let defaults: UserDefaults
//     private let keychainStore: LicenseKeychainStore
//
//     init(
//         defaults: UserDefaults = .standard,
//         keychainStore: LicenseKeychainStore = LicenseKeychainStore()
//     ) {
//         self.defaults = defaults
//         self.keychainStore = keychainStore
//     }
//
//     func loadCredentials() -> SavedLicenseCredentials? {
//         guard
//             let email = defaults.string(forKey: Self.emailDefaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
//             !email.isEmpty,
//             let licenseKey = keychainStore.readLicenseKey()
//         else {
//             return nil
//         }
//
//         return SavedLicenseCredentials(email: email, licenseKey: licenseKey)
//     }
//
//     func saveCredentials(email: String, licenseKey: String) throws {
//         let sanitizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
//         let sanitizedLicenseKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
//
//         guard !sanitizedEmail.isEmpty, !sanitizedLicenseKey.isEmpty else { return }
//
//         try keychainStore.saveLicenseKey(sanitizedLicenseKey)
//         defaults.set(sanitizedEmail, forKey: Self.emailDefaultsKey)
//     }
//
//     func clearCredentials() throws {
//         defaults.removeObject(forKey: Self.emailDefaultsKey)
//         defaults.removeObject(forKey: Self.lastCheckDateDefaultsKey)
//         defaults.removeObject(forKey: Self.lastCheckReasonDefaultsKey)
//         defaults.removeObject(forKey: Self.lastActiveValidationDateDefaultsKey)
//         try keychainStore.deleteLicenseKey()
//     }
//
//     func saveLastCheck(reason: LicenseVerificationReason, date: Date) {
//         defaults.set(reason.rawValue, forKey: Self.lastCheckReasonDefaultsKey)
//         defaults.set(date, forKey: Self.lastCheckDateDefaultsKey)
//     }
//
//     func loadLastCheckReason() -> LicenseVerificationReason? {
//         guard let rawReason = defaults.string(forKey: Self.lastCheckReasonDefaultsKey) else {
//             return nil
//         }
//
//         return LicenseVerificationReason(rawValue: rawReason)
//     }
//
//     func loadLastCheckDate() -> Date? {
//         defaults.object(forKey: Self.lastCheckDateDefaultsKey) as? Date
//     }
//
//     func saveLastActiveValidationDate(_ date: Date) {
//         defaults.set(date, forKey: Self.lastActiveValidationDateDefaultsKey)
//     }
//
//     func loadLastActiveValidationDate() -> Date? {
//         defaults.object(forKey: Self.lastActiveValidationDateDefaultsKey) as? Date
//     }
//
//     func clearLastActiveValidationDate() {
//         defaults.removeObject(forKey: Self.lastActiveValidationDateDefaultsKey)
//     }
// }
