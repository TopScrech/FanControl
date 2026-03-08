struct UpdateChangelogEntry: Hashable, Identifiable {
    let tagName: String
    let isPrerelease: Bool
    let notes: String
    
    var id: String {
        tagName
    }
}
