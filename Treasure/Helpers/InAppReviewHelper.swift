import StoreKit
import SwiftUI

enum InAppReviewHelper {
    enum Source {
        case reports
        case transactionList
    }

    private static let completedKey = "review_completed"
    private static let reportsKey = "review_reports_views"
    private static let txListKey = "review_tx_list_views"
    private static let lastPromptKey = "last_review_prompt_at"
    private static let cooldown: TimeInterval = 14 * 24 * 60 * 60

    static func maybePrompt(source: Source) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: completedKey) { return }

        switch source {
        case .reports:
            defaults.set(defaults.integer(forKey: reportsKey) + 1, forKey: reportsKey)
        case .transactionList:
            defaults.set(defaults.integer(forKey: txListKey) + 1, forKey: txListKey)
        }

        let total = defaults.integer(forKey: reportsKey) + defaults.integer(forKey: txListKey)
        guard total >= 2 else { return }

        let last = defaults.double(forKey: lastPromptKey)
        if last > 0, Date().timeIntervalSince1970 - last < cooldown { return }

        defaults.set(Date().timeIntervalSince1970, forKey: lastPromptKey)

        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        SKStoreReviewController.requestReview(in: scene)
        defaults.set(true, forKey: completedKey)
    }
}
