import SwiftUI

/// Google Contacts-style letter avatar. Palette and hash match Android `SharingDisplayHelper`.
enum SharingAvatar {
    static let colors: [Color] = [
        Color(hex: 0xEF5350),
        Color(hex: 0xEC407A),
        Color(hex: 0xAB47BC),
        Color(hex: 0x7E57C2),
        Color(hex: 0x5C6BC0),
        Color(hex: 0x42A5F5),
        Color(hex: 0x26A69A),
        Color(hex: 0x66BB6A),
        Color(hex: 0xFFA726),
        Color(hex: 0xFF7043),
        Color(hex: 0x8D6E63),
        Color(hex: 0x78909C),
    ]

    static func letter(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let ch = trimmed.first(where: { $0.isLetter || $0.isNumber }) {
            return String(ch).uppercased()
        }
        return "?"
    }

    static func color(_ name: String) -> Color {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let idx = (javaStringHash(key) & 0x7FFF_FFFF) % colors.count
        return colors[idx]
    }

    /// Matches `String.hashCode()` on the JVM (UTF-16 code units).
    private static func javaStringHash(_ s: String) -> Int {
        var h = 0
        for unit in s.utf16 {
            h = 31 &* h &+ Int(unit)
        }
        return h
    }
}

struct SharingLetterAvatar: View {
    let name: String
    var size: CGFloat = 48

    var body: some View {
        Text(SharingAvatar.letter(name))
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(SharingAvatar.color(name)))
    }
}
