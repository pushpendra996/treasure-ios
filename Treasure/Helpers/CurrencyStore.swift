import Foundation
import FirebaseAuth
import FirebaseFirestore

struct CurrencyOption: Identifiable, Hashable {
    let code: String
    let symbol: String
    let name: String
    var id: String { code }
    var label: String { "\(code)  \(symbol)" }
}

final class CurrencyStore: ObservableObject {
    static let shared = CurrencyStore()

    static let options: [CurrencyOption] = [
        CurrencyOption(code: "INR", symbol: "₹", name: "Indian Rupee"),
        CurrencyOption(code: "USD", symbol: "$", name: "US Dollar"),
        CurrencyOption(code: "EUR", symbol: "€", name: "Euro"),
        CurrencyOption(code: "GBP", symbol: "£", name: "British Pound"),
        CurrencyOption(code: "AED", symbol: "د.إ", name: "UAE Dirham"),
        CurrencyOption(code: "SGD", symbol: "S$", name: "Singapore Dollar"),
        CurrencyOption(code: "AUD", symbol: "A$", name: "Australian Dollar"),
        CurrencyOption(code: "CAD", symbol: "C$", name: "Canadian Dollar"),
    ]

    static let defaultCode = "INR"
    private static let defaultsKey = "currency"

    @Published private(set) var code: String

    var symbol: String { option(for: code).symbol }
    var label: String { option(for: code).label }

    private init() {
        if let stored = UserDefaults.standard.string(forKey: Self.defaultsKey),
           Self.options.contains(where: { $0.code == stored }) {
            code = stored
        } else if let userCode = UserDefaults.standard.dictionary(forKey: "userData")?["currency"] as? String,
                  Self.options.contains(where: { $0.code == userCode }) {
            code = userCode
        } else {
            code = Self.defaultCode
        }
    }

    func formatted(_ value: Double, fractionDigits: Int = 0) -> String {
        let absFormatted = abs(value).formatted(.number.precision(.fractionLength(fractionDigits)))
        return (value < 0 ? "-" : "") + symbol + absFormatted
    }

    func applyFromProfile(_ data: [String: Any]?) {
        guard let raw = data?["currency"] as? String else { return }
        let resolved = raw.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.options.contains(where: { $0.code == resolved }) else { return }
        UserDefaults.standard.set(resolved, forKey: Self.defaultsKey)
        if code != resolved {
            code = resolved
        }
    }

    func save(_ newCode: String) {
        guard Self.options.contains(where: { $0.code == newCode }) else { return }
        UserDefaults.standard.set(newCode, forKey: Self.defaultsKey)
        var stored = UserDefaults.standard.dictionary(forKey: "userData") ?? [:]
        stored["currency"] = newCode
        UserDefaults.standard.set(stored, forKey: "userData")
        if code != newCode {
            code = newCode
        }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).setData(
            ["currency": newCode],
            merge: true
        )
    }

    func clearLocal() {
        UserDefaults.standard.removeObject(forKey: Self.defaultsKey)
        code = Self.defaultCode
    }

    private func option(for code: String) -> CurrencyOption {
        Self.options.first(where: { $0.code == code }) ?? Self.options[0]
    }
}

func formattedAmount(_ value: Double, fractionDigits: Int = 0) -> String {
    CurrencyStore.shared.formatted(value, fractionDigits: fractionDigits)
}
