import Foundation
import SwiftUI

enum AppUpdateHelper {
    static func checkForUpdate() {
        #if DEBUG
        return
        #else
        guard let url = URL(string: StoreLinks.appStoreLookup) else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let results = json["results"] as? [[String: Any]],
                    let first = results.first,
                    let storeVersion = first["version"] as? String,
                    let trackId = first["trackId"] as? Int
                else { return }

                let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
                guard isNewer(storeVersion, than: current) else { return }
                await MainActor.run {
                    prompt(storeURL: URL(string: "https://apps.apple.com/app/id\(trackId)"))
                }
            } catch {
                // Lookup fails until the app is published; ignore.
            }
        }
        #endif
    }

    private static func isNewer(_ store: String, than current: String) -> Bool {
        let storeParts = store.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let count = max(storeParts.count, currentParts.count)
        for i in 0..<count {
            let s = i < storeParts.count ? storeParts[i] : 0
            let c = i < currentParts.count ? currentParts[i] : 0
            if s > c { return true }
            if s < c { return false }
        }
        return false
    }

    @MainActor
    private static func prompt(storeURL: URL?) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let root = scene.keyWindow?.rootViewController else { return }

        let alert = UIAlertController(
            title: L10n.string("hint_update_available_title"),
            message: L10n.string("hint_update_available_body"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.string("hint_later"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.string("hint_update_now"), style: .default) { _ in
            if let storeURL {
                UIApplication.shared.open(storeURL)
            }
        })
        topController(from: root).present(alert, animated: true)
    }

    private static func topController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topController(from: presented)
        }
        return root
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first(where: \.isKeyWindow) ?? windows.first
    }
}
