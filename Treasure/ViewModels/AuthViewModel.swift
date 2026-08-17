import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var stateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        stateListener = auth.addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func fetchUserData() async {
        guard let userId = auth.currentUser?.uid else { return }

        func store(_ data: [String: Any]) {
            let userData: [String: Any] = [
                "id": userId,
                "name": data["name"] as? String ?? "",
                "email": data["email"] as? String ?? "",
                "phoneNumber": auth.currentUser?.phoneNumber ?? "",
                "currency": data["currency"] as? String ?? CurrencyStore.defaultCode
            ]
            UserDefaults.standard.set(userData, forKey: "userData")
            CurrencyStore.shared.applyFromProfile(data)
        }

        if let cache = try? await db.collection("users").document(userId).getDocument(source: .cache),
           let data = cache.data() {
            store(data)
        }
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data() {
                store(data)
            }
        } catch {
            if UserDefaults.standard.dictionary(forKey: "userData") == nil {
                self.error = error.localizedDescription
            }
        }
    }
    
    deinit {
        if let listener = stateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }
} 
