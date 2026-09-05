// License purchasing disabled for this distribution
// import Foundation
// import Security
//
// struct LicenseKeychainStore {
//     private static let service = "dev.topscrech.FanControl.license"
//     private static let account = "default"
//
//     func readLicenseKey() -> String? {
//         var query = baseQuery
//         query[kSecReturnData as String] = true
//         query[kSecMatchLimit as String] = kSecMatchLimitOne
//
//         var result: AnyObject?
//         let status = SecItemCopyMatching(query as CFDictionary, &result)
//
//         if status == errSecItemNotFound {
//             return nil
//         }
//
//         guard
//             status == errSecSuccess,
//             let data = result as? Data,
//             let licenseKey = String(data: data, encoding: .utf8),
//             !licenseKey.isEmpty
//         else {
//             return nil
//         }
//
//         return licenseKey
//     }
//
//     func saveLicenseKey(_ licenseKey: String) throws {
//         let sanitizedKey = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
//         guard !sanitizedKey.isEmpty else { return }
//
//         let data = Data(sanitizedKey.utf8)
//
//         var addQuery = baseQuery
//         addQuery[kSecValueData as String] = data
//
//         let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
//
//         if addStatus == errSecDuplicateItem {
//             let attributesToUpdate = [kSecValueData as String: data]
//             let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributesToUpdate as CFDictionary)
//
//             guard updateStatus == errSecSuccess else {
//                 throw LicenseKeychainStoreError.saveFailed(status: updateStatus)
//             }
//
//             return
//         }
//
//         guard addStatus == errSecSuccess else {
//             throw LicenseKeychainStoreError.saveFailed(status: addStatus)
//         }
//     }
//
//     func deleteLicenseKey() throws {
//         let status = SecItemDelete(baseQuery as CFDictionary)
//
//         guard status == errSecSuccess || status == errSecItemNotFound else {
//             throw LicenseKeychainStoreError.deleteFailed(status: status)
//         }
//     }
//
//     private var baseQuery: [String: Any] {[
//         kSecClass as String: kSecClassGenericPassword,
//         kSecAttrService as String: Self.service,
//         kSecAttrAccount as String: Self.account
//     ]}
// }
