import Foundation

nonisolated struct ComponentRelease: Comparable {
    let version: String
    let build: String

    init(version: String, build: String) throws {
        guard Self.isNumericVersion(version), Self.isNumericVersion(build) else {
            throw NSError(domain: "ComponentRelease", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid component version/build"])
        }
        self.version = version
        self.build = build
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        let order = lhs.version.compare(rhs.version, options: .numeric)
        return order == .orderedAscending || (order == .orderedSame && lhs.build.compare(rhs.build, options: .numeric) == .orderedAscending)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.version.compare(rhs.version, options: .numeric) == .orderedSame && lhs.build.compare(rhs.build, options: .numeric) == .orderedSame
    }

    private static func isNumericVersion(_ value: String) -> Bool {
        !value.isEmpty && value.split(separator: ".", omittingEmptySubsequences: false).allSatisfy {
            !$0.isEmpty && $0.utf8.allSatisfy { (48...57).contains($0) }
        }
    }
}
