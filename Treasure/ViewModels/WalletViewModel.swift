import Foundation
import FirebaseFirestore
import FirebaseAuth

class WalletViewModel: ObservableObject {
    @Published var balance: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    init() {
        fetchWalletBalance()
    }
    
    func fetchWalletBalance() {
        guard let userId = userId else { return }
        isLoading = true
        
        db.collection("wallets").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.error = error.localizedDescription
                return
            }
            
            if let data = snapshot?.data() {
                self.balance = data["balance"] as? Double ?? 0.0
            }
        }
    }
    
    func updateBalance(amount: Double, isAddition: Bool) async throws {
        guard let userId = userId else { return }
        
        let newBalance = isAddition ? balance + amount : balance - amount
        
        try await db.collection("wallets").document(userId).setData([
            "balance": newBalance,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
} 