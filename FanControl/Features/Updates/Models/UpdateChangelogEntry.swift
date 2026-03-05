import Foundation

struct UpdateChangelogEntry: Hashable, Identifiable {
    let tagName: String
    let notes: String
    
    var id: String {
        tagName
    }
}
