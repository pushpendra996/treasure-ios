import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications

enum FcmTokenRegistrar {
    static func register(token: String? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let apply: (String) -> Void = { t in
            Firestore.firestore().collection("users").document(uid).setData([
                "token": t,
                "tokenUpdatedAt": FieldValue.serverTimestamp(),
            ], merge: true)
        }
        if let token, !token.isEmpty {
            apply(token)
            return
        }
        Messaging.messaging().token { token, _ in
            if let token, !token.isEmpty {
                apply(token)
            }
        }
    }

    static func requestPermissionAndRegister() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                register()
            }
        }
    }
}
