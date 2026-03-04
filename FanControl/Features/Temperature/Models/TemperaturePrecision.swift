import SwiftUI

enum TemperaturePrecision: String, CaseIterable, Identifiable {
    case whole, tenths
    
    var id: String { rawValue }
    
    var title: LocalizedStringKey {
        switch self {
        case .whole: "Whole numbers"
        case .tenths: "Tenths"
        }
    }
    
    var showsTenths: Bool {
        self == .tenths
    }
}
