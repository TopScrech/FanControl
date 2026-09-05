import Foundation
import Security

nonisolated enum ComponentSignature {
    static func verify(_ url: URL) throws {
        var code: SecStaticCode?
        var requirement: SecRequirement?
        let expression = "anchor apple generic and certificate leaf[subject.OU] = \"\(ComponentConfiguration.teamIdentifier)\" and identifier \"\(ComponentConfiguration.bundleIdentifier)\""
        let flags = SecCSFlags(rawValue: kSecCSStrictValidate | kSecCSCheckNestedCode | kSecCSCheckAllArchitectures)
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess,
              let code,
              SecRequirementCreateWithString(expression as CFString, [], &requirement) == errSecSuccess,
              let requirement,
              SecStaticCodeCheckValidity(code, flags, requirement) == errSecSuccess else {
            throw NSError(domain: "ComponentSignature", code: 1, userInfo: [NSLocalizedDescriptionKey: "The component signature could not be verified at \(url.path)"])
        }
    }
}
