import SwiftUI

enum AppLanguageOption: String, CaseIterable, Identifiable {
    case english, dutch, german, french, russian, ukrainian
    
    static let storageKey = "preferredAppLanguageOption"
    static let appleLanguagesKey = "AppleLanguages"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: "English"
        case .dutch: "Nederlands"
        case .german: "Deutsch"
        case .french: "Français"
        case .russian: "Русский"
        case .ukrainian: "Українська"
        }
    }
    
    var flagEmoji: String {
        switch self {
        case .english: "🇺🇸"
        case .dutch: "🇳🇱"
        case .german: "🇩🇪"
        case .french: "🇫🇷"
        case .russian: "🇷🇺"
        case .ukrainian: "🇺🇦"
        }
    }
    
    var locale: Locale {
        switch self {
        case .english: Locale(identifier: "en")
        case .dutch: Locale(identifier: "nl")
        case .german: Locale(identifier: "de")
        case .french: Locale(identifier: "fr")
        case .russian: Locale(identifier: "ru")
        case .ukrainian: Locale(identifier: "uk")
        }
    }
    
    var languageCode: String {
        switch self {
        case .english: "en"
        case .dutch: "nl"
        case .german: "de"
        case .french: "fr"
        case .russian: "ru"
        case .ukrainian: "uk"
        }
    }
}

enum AppLanguageManager {
    private static let supportedLanguageCodes = ["en", "nl", "de", "fr", "ru", "uk"]
    private static let fallbackLanguageCode = "en"
    
    static var defaultOption: AppLanguageOption {
        option(for: resolvedSystemLanguageCode())
    }
    
    static func option(from rawValue: String) -> AppLanguageOption {
        if rawValue == "system" {
            return defaultOption
        }
        
        return AppLanguageOption(rawValue: rawValue) ?? defaultOption
    }
    
    static func locale(for option: AppLanguageOption) -> Locale {
        option.locale
    }
    
    static func apply(option: AppLanguageOption) {
        UserDefaults.standard.set([option.languageCode], forKey: AppLanguageOption.appleLanguagesKey)
    }
    
    private static func option(for languageCode: String) -> AppLanguageOption {
        switch languageCode {
        case "nl": .dutch
        case "de": .german
        case "fr": .french
        case "ru": .russian
        case "uk": .ukrainian
        default: .english
        }
    }
    
    private static func resolvedSystemLanguageCode() -> String {
        for preferredLanguage in Locale.preferredLanguages {
            let normalized = preferredLanguage.lowercased().replacingOccurrences(of: "_", with: "-")
            let baseLanguage = normalized.split(separator: "-").first.map(String.init) ?? normalized
            
            if supportedLanguageCodes.contains(baseLanguage) {
                return baseLanguage
            }
        }
        
        return fallbackLanguageCode
    }
}
