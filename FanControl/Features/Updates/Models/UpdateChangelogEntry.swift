import SwiftUI

struct UpdateChangelogEntry: Equatable, Identifiable {
    let tagName: String
    let isPrerelease: Bool
    let notes: LocalizedStringKey
    
    var id: String {
        tagName
    }
}
