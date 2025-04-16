import SwiftUI
import FirebaseCore
import FirebaseAuth

// Import ViewModels
import Foundation

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Configure Phone Auth
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true // Set to true only for testing
        
        return true
    }
    
    func application(_ application: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle reCAPTCHA URL scheme
        return Auth.auth().canHandle(url)
    }
    
    func application(_ application: UIApplication,
                    continue userActivity: NSUserActivity,
                    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Handle universal links
        if let url = userActivity.webpageURL {
            return Auth.auth().canHandle(url)
        }
        return false
    }
    
    func application(_ application: UIApplication,
                    didReceiveRemoteNotification notification: [AnyHashable : Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(notification) {
            completionHandler(.noData)
            return
        }
        // Handle other types of notifications here if needed
        completionHandler(.noData)
    }
}

@main
struct TreasureApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appVM = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appVM.transactionVM)
                .environmentObject(appVM.categoryVM)
                .environmentObject(appVM.walletVM)
        }
    }
} 
