import Foundation

enum AdConfig {
    /// Android app id is `ca-app-pub-7864166174311789~8633624285`. Replace these
    /// with the iOS AdMob app + rewarded unit before a production release.
    static let productionAppID = "ca-app-pub-3940256099942544~1458002511"
    static let productionRewardedID = "ca-app-pub-3940256099942544/1712485313"

    static let testAppID = "ca-app-pub-3940256099942544~1458002511"
    static let testRewardedID = "ca-app-pub-3940256099942544/1712485313"

    static var appID: String {
        #if DEBUG
        testAppID
        #else
        productionAppID
        #endif
    }

    static var rewardedID: String {
        #if DEBUG
        testRewardedID
        #else
        productionRewardedID
        #endif
    }
}
