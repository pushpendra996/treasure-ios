import Foundation

enum L10n {
    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, locale: LanguageStore.shared.locale)
    }

    static func format(_ key: String.LocalizationValue, _ args: CVarArg...) -> String {
        String(format: string(key), locale: LanguageStore.shared.locale, arguments: args)
    }
}
