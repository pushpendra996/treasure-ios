import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var greeting = ""
    @Published var personName = ""
    @Published var personMobileNo: String?
    @Published var appInfo: String?
    @Published var isDeleting = false
    @Published var error: String?

    func onAppear() {
        let hour = Calendar.current.component(.hour, from: Date())
        greeting = switch hour {
        case 0..<12: L10n.string("hint_greeting_morning")
        case 12..<17: L10n.string("hint_greeting_afternoon")
        default: L10n.string("hint_greeting_evening")
        }

        if let userData = UserDefaults.standard.dictionary(forKey: "userData") {
            let name = userData["name"] as? String ?? ""
            personName = name.isEmpty ? L10n.string("hint_guest") : name
            personMobileNo = Auth.auth().currentUser?.phoneNumber
        } else {
            personName = L10n.string("hint_guest")
            personMobileNo = Auth.auth().currentUser?.phoneNumber
        }

        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            appInfo = L10n.format("hint_app_version", version, build)
        }
    }

    func onTapProfile() {
        NotificationCenter.default.post(name: .openUserDetails, object: nil)
    }

    func signOut() {
        SessionCleanup.signOutAndClear()
    }

    func deleteAccount() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isDeleting = true
        defer { isDeleting = false }
        let db = Firestore.firestore()
        try? await db.collection("transaction").document(uid).delete()
        try? await db.collection("wallet").document(uid).delete()
        try? await db.collection("users").document(uid).delete()
        SessionCleanup.signOutAndClear()
    }
}
