import FirebaseAuth
import FirebaseFirestore
import Foundation

enum SessionCleanup {
    static func signOutAndClear() {
        let language = UserDefaults.standard.string(forKey: LanguageStore.languageKey)
        let selected = UserDefaults.standard.bool(forKey: LanguageStore.selectedKey)
        let reminders = UserDefaults.standard.object(forKey: ExpenseReminderScheduler.enabledKey)

        try? Auth.auth().signOut()
        UserDefaults.standard.removeObject(forKey: "userData")
        CurrencyStore.shared.clearLocal()

        if let language {
            UserDefaults.standard.set(language, forKey: LanguageStore.languageKey)
        }
        UserDefaults.standard.set(selected, forKey: LanguageStore.selectedKey)
        if let reminders {
            UserDefaults.standard.set(reminders, forKey: ExpenseReminderScheduler.enabledKey)
        }

        let db = Firestore.firestore()
        db.terminate { _ in
            db.clearPersistence { _ in }
        }
    }
}
