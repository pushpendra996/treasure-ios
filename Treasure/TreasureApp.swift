import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        Auth.auth().settings?.isAppVerificationDisabledForTesting = {
            #if DEBUG
            true
            #else
            false
            #endif
        }()

        RewardedAds.requestConsentThenPreload()
        AppUpdateHelper.checkForUpdate()

        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            SharingDeepLinkStore.shared.capture(remote)
        }
        return true
    }

    func application(_ application: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return Auth.auth().canHandle(url)
    }

    func application(_ application: UIApplication,
                    continue userActivity: NSUserActivity,
                    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let url = userActivity.webpageURL {
            return Auth.auth().canHandle(url)
        }
        return false
    }

    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
        FcmTokenRegistrar.register()
    }

    func application(_ application: UIApplication,
                    didReceiveRemoteNotification notification: [AnyHashable : Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        SharingDeepLinkStore.shared.capture(notification)
        completionHandler(.noData)
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        FcmTokenRegistrar.register(token: fcmToken)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if notification.request.identifier.hasPrefix("treasure.expense.reminder") {
            completionHandler([])
            return
        }
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        SharingDeepLinkStore.shared.capture(response.notification.request.content.userInfo)
        completionHandler()
    }
}

@main
struct TreasureApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appVM = AppViewModel()
    @ObservedObject private var languageStore = LanguageStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appVM.transactionVM)
                .environmentObject(appVM.categoryVM)
                .environmentObject(appVM.walletVM)
                .environment(\.locale, languageStore.locale)
                .environment(\.layoutDirection, languageStore.layoutDirection)
                .accentColor(TreasureTheme.purple)
                .id(languageStore.code)
        }
    }
}
