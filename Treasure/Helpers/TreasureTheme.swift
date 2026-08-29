import SwiftUI

enum TreasureTheme {
    static let purple = Color(red: 0x89 / 255, green: 0x65 / 255, blue: 0xFB / 255)
    static let purpleDark = Color(red: 0x61 / 255, green: 0x31 / 255, blue: 0xFA / 255)
    static let title = Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x2E / 255)
    static let languageBackground = Color(red: 0xF9 / 255, green: 0xF9 / 255, blue: 0xFB / 255)
    static let languageFooter = Color(red: 0xF3 / 255, green: 0xEE / 255, blue: 0xFF / 255)
    static let languageDivider = Color(red: 0xE8 / 255, green: 0xE8 / 255, blue: 0xE8 / 255)
    static let income = Color(red: 0x52 / 255, green: 0x99 / 255, blue: 0x00 / 255)
    static let expense = Color(red: 0xC6 / 255, green: 0x28 / 255, blue: 0x28 / 255)
    static let screenBackground = Color(red: 0xF6 / 255, green: 0xF6 / 255, blue: 0xF6 / 255)

    static func tileBackground() -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(purple.opacity(0.12))
    }
}
