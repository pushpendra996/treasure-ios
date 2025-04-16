import Foundation
import FirebaseFirestore
import FirebaseAuth

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let limit: Int = 20
    
    func addTransaction(_ transaction: Transaction) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "TransactionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let year = Calendar.current.component(.year, from: transaction.date)
        let ref = db.collection("transaction")
            .document(userId)
            .collection(String(year))
        
        try await ref.addDocument(data: transaction.dictionary)
        await updateWalletAmount(for: transaction)
    }
    
    func fetchTransactions(forDate date: Date = Date()) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let year = Calendar.current.component(.year, from: date)
        
        await MainActor.run { self.isLoading = true }
        
        do {
            let query = db.collection("transaction")
                .document(userId)
                .collection(String(year))
                .order(by: "transaction_date", descending: true)
                .limit(to: limit)
            
            if let lastDoc = lastDocument {
                query.start(afterDocument: lastDoc)
            }
            
            let snapshot = try await query.getDocuments()
            
            let newTransactions = snapshot.documents.compactMap { Transaction(document: $0) }
            
            await MainActor.run {
                self.transactions.append(contentsOf: newTransactions)
                self.lastDocument = snapshot.documents.last
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "TransactionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let year = Calendar.current.component(.year, from: transaction.date)
        
        let snapshot = try await db.collection("transaction")
            .document(userId)
            .collection(String(year))
            .whereField("transaction_id", isEqualTo: transaction.id)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw NSError(domain: "TransactionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction not found"])
        }
        
        try await document.reference.delete()
        await updateWalletAmount(for: transaction, isDelete: true)
        
        await MainActor.run {
            self.transactions.removeAll { $0.id == transaction.id }
        }
    }
    
    private func updateWalletAmount(for transactionData: Transaction, isDelete: Bool = false) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let year = Calendar.current.component(.year, from: transactionData.date)
        let month = Calendar.current.component(.month, from: transactionData.date)
        let monthString = String(format: "%02d", month)
        
        let walletRef = db.collection("wallet")
            .document(userId)
            .collection(String(year))
            .document(monthString)
        
        do {
            let _ = try await db.runTransaction({ (transaction, errorPointer) -> Any? in
                let walletDoc: DocumentSnapshot
                do {
                    walletDoc = try transaction.getDocument(walletRef)
                } catch let fetchError as NSError {
                    errorPointer?.pointee = fetchError
                    return nil
                }
                
                var currentAmount: Double = 0
                let field = transactionData.type == .income ? "income" : "expenses"
                
                if let currentString = walletDoc.data()?[field] as? String {
                    currentAmount = Double(currentString) ?? 0
                }
                
                if isDelete {
                    currentAmount -= transactionData.amount
                } else {
                    currentAmount += transactionData.amount
                }
                
                transaction.updateData([
                    field: String(currentAmount),
                    "updated_at": String(Int(Date().timeIntervalSince1970 * 1000))
                ], forDocument: walletRef)
                
                return true
            })
        } catch {
            print("Transaction failed: \(error)")
        }
    }
} 
