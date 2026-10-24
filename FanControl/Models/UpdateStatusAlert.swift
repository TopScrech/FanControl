import SwiftUI

struct UpdateStatusAlert: Identifiable {
    let id = UUID()
    let title: LocalizedStringKey
    let message: LocalizedStringKey
}
