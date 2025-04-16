import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class UserDetailsViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    
    init() {
        if let userData = UserDefaults.standard.dictionary(forKey: "userData") {
            name = userData["name"] as? String ?? ""
            email = userData["email"] as? String ?? ""
        }
    }
    
    func saveUserDetails() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        error = nil
        
        do {
            let userData: [String: Any] = [
                "name": name,
                "email": email,
                "updated_at": Date().timeIntervalSince1970
            ]
            
            try await db.collection("users").document(userId).setData(userData, merge: true)
            
            // Update local storage
            var storedData = UserDefaults.standard.dictionary(forKey: "userData") ?? [:]
            storedData["name"] = name
            storedData["email"] = email
            UserDefaults.standard.set(storedData, forKey: "userData")
            
            NotificationCenter.default.post(name: .userDetailsSaved, object: nil)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
} 