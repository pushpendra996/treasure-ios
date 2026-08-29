import Foundation

enum StoreLinks {
    static let website = "https://treasuremoney.in"
    static let privacyPolicy = "https://treasuremoney.in/privacy-policy"
    static let terms = "https://treasuremoney.in/terms-and-conditions"
    static let playStore = "https://play.google.com/store/apps/details?id=com.treasure.money"
    /// Replace with the live App Store URL after the first publish.
    static let appStore = "https://apps.apple.com/app/id000000000"
    static let appStoreLookup = "https://itunes.apple.com/lookup?bundleId=com.treasure.money"

    static var shareURL: String { website }
}
