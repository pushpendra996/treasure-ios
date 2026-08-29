import GoogleMobileAds
import UserMessagingPlatform
import UIKit

enum RewardedAds {
    private static let cooldown: TimeInterval = 60
    private static let inFlightWait: TimeInterval = 0.8
    private static let addInterval = 4

    private static var rewardedAd: RewardedAd?
    private static var loading = false
    private static var lastShownAt: TimeInterval = 0
    private static var showing = false
    private static var fullScreenDelegate: RewardedFullScreenDelegate?

    static func initialize() {
        MobileAds.shared.start { _ in
            preload()
        }
    }

    static func requestConsentThenPreload() {
        let parameters = RequestParameters()
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { _ in
            Task { @MainActor in
                do {
                    try await ConsentForm.loadAndPresentIfRequired(from: nil)
                } catch {
                    // Continue to initialize ads using any prior consent.
                }
                initialize()
            }
        }
    }

    static func preload() {
        guard rewardedAd == nil, !loading else { return }
        guard NetworkMonitor.shared.isConnected else { return }
        guard ConsentInformation.shared.canRequestAds else { return }
        loading = true
        Task {
            defer { loading = false }
            do {
                rewardedAd = try await RewardedAd.load(with: AdConfig.rewardedID, request: Request())
            } catch {
                rewardedAd = nil
            }
        }
    }

    static func onTransactionSaved() {
        let next = UserDefaults.standard.integer(forKey: "rewarded_add_count") + 1
        UserDefaults.standard.set(next, forKey: "rewarded_add_count")
    }

    static func showThenForAddTransaction(onContinue: @escaping () -> Void) {
        let count = UserDefaults.standard.integer(forKey: "rewarded_add_count")
        if count < addInterval {
            onContinue()
            return
        }
        let shownBefore = lastShownAt
        showThen {
            if lastShownAt != shownBefore {
                UserDefaults.standard.set(0, forKey: "rewarded_add_count")
            }
            onContinue()
        }
    }

    static func showThen(onContinue: @escaping () -> Void) {
        guard NetworkMonitor.shared.isConnected, !showing else {
            onContinue()
            return
        }
        if Date().timeIntervalSince1970 - lastShownAt < cooldown {
            onContinue()
            return
        }
        if let rewardedAd {
            present(rewardedAd, onContinue: onContinue)
            return
        }
        if loading {
            DispatchQueue.main.asyncAfter(deadline: .now() + inFlightWait) {
                if let rewardedAd, Date().timeIntervalSince1970 - lastShownAt >= cooldown {
                    present(rewardedAd, onContinue: onContinue)
                } else {
                    onContinue()
                }
            }
            return
        }
        preload()
        onContinue()
    }

    private static func present(_ ad: RewardedAd, onContinue: @escaping () -> Void) {
        guard !showing, let host = topViewController() else {
            onContinue()
            return
        }
        showing = true
        rewardedAd = nil
        var continued = false
        let proceed = {
            guard !continued else { return }
            continued = true
            showing = false
            lastShownAt = Date().timeIntervalSince1970
            onContinue()
            preload()
        }
        let delegate = RewardedFullScreenDelegate(onFinish: proceed)
        fullScreenDelegate = delegate
        ad.fullScreenContentDelegate = delegate
        ad.present(from: host, userDidEarnRewardHandler: {})
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var root = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = root?.presentedViewController {
            root = presented
        }
        return root
    }
}

private final class RewardedFullScreenDelegate: NSObject, FullScreenContentDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { onFinish() }
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onFinish()
    }
}
