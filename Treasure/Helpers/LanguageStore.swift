import Combine
import SwiftUI

struct LanguageOption: Identifiable, Equatable {
    enum Category {
        case international
        case indian
    }

    let code: String
    let nativeLabel: String
    let englishLabel: String
    let badgeText: String
    let badgeColor: Color
    let category: Category
    let rtl: Bool

    var id: String { code }
}

final class LanguageStore: ObservableObject {
    static let shared = LanguageStore()

    static let languageKey = "local_language"
    static let selectedKey = "language_selected"

    static let options: [LanguageOption] = [
        LanguageOption(code: "en", nativeLabel: "English", englishLabel: "English", badgeText: "EN", badgeColor: Color(hex: 0x8965FB), category: .international, rtl: false),
        LanguageOption(code: "fr", nativeLabel: "Français", englishLabel: "French", badgeText: "FR", badgeColor: Color(hex: 0x5B8DEF), category: .international, rtl: false),
        LanguageOption(code: "es", nativeLabel: "Español", englishLabel: "Spanish", badgeText: "ES", badgeColor: Color(hex: 0x4CAF50), category: .international, rtl: false),
        LanguageOption(code: "ar", nativeLabel: "العربية", englishLabel: "Arabic", badgeText: "AR", badgeColor: Color(hex: 0xB39DDB), category: .international, rtl: true),
        LanguageOption(code: "hi", nativeLabel: "हिन्दी", englishLabel: "Hindi", badgeText: "हि", badgeColor: Color(hex: 0xFF9800), category: .indian, rtl: false),
        LanguageOption(code: "bn", nativeLabel: "বাংলা", englishLabel: "Bengali", badgeText: "বা", badgeColor: Color(hex: 0x8BC34A), category: .indian, rtl: false),
        LanguageOption(code: "te", nativeLabel: "తెలుగు", englishLabel: "Telugu", badgeText: "తె", badgeColor: Color(hex: 0x7C4DFF), category: .indian, rtl: false),
        LanguageOption(code: "mr", nativeLabel: "मराठी", englishLabel: "Marathi", badgeText: "मर", badgeColor: Color(hex: 0xE91E63), category: .indian, rtl: false),
        LanguageOption(code: "ta", nativeLabel: "தமிழ்", englishLabel: "Tamil", badgeText: "த", badgeColor: Color(hex: 0x009688), category: .indian, rtl: false),
        LanguageOption(code: "gu", nativeLabel: "ગુજરાતી", englishLabel: "Gujarati", badgeText: "ગુ", badgeColor: Color(hex: 0xFFC107), category: .indian, rtl: false),
        LanguageOption(code: "kn", nativeLabel: "ಕನ್ನಡ", englishLabel: "Kannada", badgeText: "ಕ", badgeColor: Color(hex: 0x7E57C2), category: .indian, rtl: false),
        LanguageOption(code: "ml", nativeLabel: "മലയാളം", englishLabel: "Malayalam", badgeText: "മ", badgeColor: Color(hex: 0x26A69A), category: .indian, rtl: false),
        LanguageOption(code: "pa", nativeLabel: "ਪੰਜਾਬੀ", englishLabel: "Punjabi", badgeText: "ਪ", badgeColor: Color(hex: 0xFF7043), category: .indian, rtl: false),
    ]

    static var internationalOptions: [LanguageOption] {
        options.filter { $0.category == .international }
    }

    static var indianOptions: [LanguageOption] {
        options.filter { $0.category == .indian }
    }

    @Published private(set) var code: String
    @Published private(set) var hasSelected: Bool

    var current: LanguageOption {
        Self.options.first(where: { $0.code == code }) ?? Self.options[0]
    }

    var locale: Locale { Locale(identifier: code) }
    var layoutDirection: LayoutDirection { current.rtl ? .rightToLeft : .leftToRight }
    var nativeLabel: String { current.nativeLabel }

    private init() {
        let defaults = UserDefaults.standard
        let saved = defaults.string(forKey: Self.languageKey)
        if let saved, Self.options.contains(where: { $0.code == saved }) {
            code = saved
        } else {
            let device = Locale.current.language.languageCode?.identifier ?? "en"
            code = Self.options.contains(where: { $0.code == device }) ? device : "en"
        }
        hasSelected = defaults.bool(forKey: Self.selectedKey)
        applyAppleLanguages()
    }

    func save(_ newCode: String) {
        guard Self.options.contains(where: { $0.code == newCode }) else { return }
        UserDefaults.standard.set(newCode, forKey: Self.languageKey)
        UserDefaults.standard.set(true, forKey: Self.selectedKey)
        code = newCode
        hasSelected = true
        applyAppleLanguages()
        ExpenseReminderScheduler.rescheduleIfEnabled()
    }

    private func applyAppleLanguages() {
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
