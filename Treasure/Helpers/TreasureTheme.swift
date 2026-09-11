import SwiftUI
import UIKit

enum TreasureTheme {
    static let purple = Color(red: 0x89 / 255, green: 0x65 / 255, blue: 0xFB / 255)
    static let purpleDark = Color(red: 0x61 / 255, green: 0x31 / 255, blue: 0xFA / 255)
    static let title = Color(red: 0x1A / 255, green: 0x1A / 255, blue: 0x2E / 255)
    static let languageBackground = Color(red: 0xF9 / 255, green: 0xF9 / 255, blue: 0xFB / 255)
    static let languageFooter = Color(red: 0xF3 / 255, green: 0xEE / 255, blue: 0xFF / 255)
    static let languageDivider = Color(red: 0xE8 / 255, green: 0xE8 / 255, blue: 0xE8 / 255)
    static let income = Color(red: 0x52 / 255, green: 0x99 / 255, blue: 0x00 / 255)
    static let expense = Color(red: 0xC6 / 255, green: 0x28 / 255, blue: 0x28 / 255)
    static let saving = Color(hex: 0xF57C00)
    static let screenBackground = Color(red: 0xF6 / 255, green: 0xF6 / 255, blue: 0xF6 / 255)
    static let summaryExpenseBg = adaptiveColor(light: 0xFDECEC, dark: 0x3A2428)
    static let summaryIncomeBg = adaptiveColor(light: 0xE8F6EA, dark: 0x1C3228)
    static let summaryBalanceBg = adaptiveColor(light: 0xEEE8FE, dark: 0x2A2440)
    static let summarySavingBg = adaptiveColor(light: 0xFFF6DF, dark: 0x3A3220)

    private static func adaptiveColor(light: UInt, dark: UInt) -> Color {
        Color(uiColor: UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }

    static func tileBackground() -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(purple.opacity(0.12))
    }
}
