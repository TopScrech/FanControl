import Foundation

struct UpdateStatusAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
