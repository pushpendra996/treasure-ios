import Foundation
import FirebaseFirestore
import FirebaseAuth

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedMonth: Date = Date()
    @Published var hasMore = false
    @Published var monthIncome: Double = 0
    @Published var monthExpenses: Double = 0

    private let db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    private let limit: Int = 20

    var monthLabel: String {
        let calendar = Calendar.current
        if calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month) {
            let name = selectedMonth.formatted(.dateTime.month(.wide))
            return L10n.format("hint_current_month", name)
        }
        return selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    func shiftMonth(by value: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = next
        }
    }

    func addTransaction(_ transaction: Transaction) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "TransactionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let year = Calendar.current.component(.year, from: transaction.date)
        let ref = db.collection("transaction")
            .document(userId)
            .collection(String(year))

        do {
            let doc = try await ref.addDocument(data: transaction.dictionary)
            var stored = transaction
            stored.documentId = doc.documentID
            await updateWalletAmount(for: stored)
            await MainActor.run {
                if Calendar.current.isDate(stored.date, equalTo: self.selectedMonth, toGranularity: .month) {
                    self.transactions.insert(stored, at: 0)
                }
            }
        } catch {
            if isOfflineError(error) {
                await MainActor.run {
                    if Calendar.current.isDate(transaction.date, equalTo: self.selectedMonth, toGranularity: .month) {
                        self.transactions.insert(transaction, at: 0)
                    }
                }
                return
            }
            throw error
        }
    }

    func updateTransaction(original: Transaction, updated: Transaction) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "TransactionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let year = Calendar.current.component(.year, from: original.date)
        let collection = db.collection("transaction")
            .document(userId)
            .collection(String(year))

        let document: DocumentSnapshot
        if let documentId = original.documentId, !documentId.isEmpty {
            document = try await collection.document(documentId).getDocumentAvailable()
        } else {
            let snapshot = try await collection
                .whereField("transaction_id", isEqualTo: original.id)
                .limit(to: 1)
                .getDocumentsAvailable()
            guard let found = snapshot.documents.first else {
                throw NSError(domain: "TransactionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction not found"])
            }
            document = found
        }

        guard document.exists else {
            throw NSError(domain: "TransactionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction not found"])
        }

        do {
            try await document.reference.updateData(updated.dictionary)
        } catch {
            if !isOfflineError(error) { throw error }
        }

        await updateWalletAmount(for: original, isDelete: true)
        await updateWalletAmount(for: updated)

        await MainActor.run {
            if let index = self.transactions.firstIndex(where: { $0.id == original.id }) {
                var next = updated
                next.documentId = document.documentID
                if Calendar.current.isDate(next.date, equalTo: self.selectedMonth, toGranularity: .month) {
                    self.transactions[index] = next
                } else {
                    self.transactions.remove(at: index)
                }
            }
        }
    }

    func duplicateTransaction(_ transaction: Transaction) async throws {
        guard Auth.auth().currentUser?.uid != nil else {
            throw NSError(domain: "TransactionError", code: -1, userInfo: [NSLocalizedDescriptionKey: L10n.string("hint_please_log_in")])
        }
        let copy = Transaction(
            userId: transaction.userId,
            amount: transaction.amount,
            type: transaction.type,
            category: transaction.category,
            remark: transaction.remark,
            date: Date(),
            tags: transaction.tags
        )
        try await addTransaction(copy)
    }

    func fetchTransactions(forDate date: Date? = nil, reset: Bool = false) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let target = date ?? selectedMonth

        if reset {
            await MainActor.run {
                self.lastDocument = nil
                self.hasMore = false
            }
        }

        await MainActor.run { self.isLoading = true }

        let bounds = monthBounds(for: target)
        let year = Calendar.current.component(.year, from: target)

        var query: Query = db.collection("transaction")
            .document(userId)
            .collection(String(year))
            .whereField("transaction_date", isGreaterThanOrEqualTo: bounds.start)
            .whereField("transaction_date", isLessThan: bounds.end)
            .order(by: "transaction_date", descending: true)
            .limit(to: limit)

        if !reset, let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        if reset, let cache = try? await query.getDocuments(source: .cache) {
            await applySnapshot(cache, reset: true)
        }
        if reset {
            await fetchMonthWallet(userId: userId, date: target)
        }

        do {
            let snapshot = try await query.getDocuments(source: .server)
            await applySnapshot(snapshot, reset: reset)
        } catch {
            if reset {
                if let fallback = try? await query.getDocumentsAvailable() {
                    await applySnapshot(fallback, reset: true)
                } else {
                    await MainActor.run {
                        if self.transactions.isEmpty {
                            self.transactions = []
                        }
                        self.isLoading = false
                    }
                }
            } else {
                await MainActor.run { self.isLoading = false }
            }
        }
    }

    func deleteTransaction(_ transaction: Transaction) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "TransactionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let year = Calendar.current.component(.year, from: transaction.date)
        let collection = db.collection("transaction")
            .document(userId)
            .collection(String(year))

        let document: DocumentSnapshot
        if let documentId = transaction.documentId, !documentId.isEmpty {
            document = try await collection.document(documentId).getDocumentAvailable()
        } else {
            let snapshot = try await collection
                .whereField("transaction_id", isEqualTo: transaction.id)
                .limit(to: 1)
                .getDocumentsAvailable()
            guard let found = snapshot.documents.first else {
                throw NSError(domain: "TransactionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Transaction not found"])
            }
            document = found
        }

        do {
            try await document.reference.delete()
        } catch {
            if !isOfflineError(error) { throw error }
        }

        await updateWalletAmount(for: transaction, isDelete: true)

        await MainActor.run {
            self.transactions.removeAll { $0.id == transaction.id }
        }
    }

    private func applySnapshot(_ snapshot: QuerySnapshot, reset: Bool) async {
        let newTransactions = snapshot.documents.compactMap { Transaction(document: $0) }
        await MainActor.run {
            if reset {
                self.transactions = newTransactions
            } else {
                self.transactions.append(contentsOf: newTransactions)
            }
            self.lastDocument = snapshot.documents.last
            self.hasMore = snapshot.documents.count >= self.limit
            self.isLoading = false
        }
    }

    private func fetchMonthWallet(userId: String, date: Date) async {
        let year = Calendar.current.component(.year, from: date)
        let month = String(format: "%02d", Calendar.current.component(.month, from: date))
        let walletRef = db.collection("wallet")
            .document(userId)
            .collection(String(year))
            .document(month)
        let snap = try? await walletRef.getDocumentAvailable()
        let data = snap?.data() ?? [:]
        let income = numberValue(data["income"])
        let expenses = numberValue(data["expenses"])
        await MainActor.run {
            self.monthIncome = income
            self.monthExpenses = expenses
        }
    }

    private func numberValue(_ value: Any?) -> Double {
        if let d = value as? Double { return d }
        if let n = value as? NSNumber { return n.doubleValue }
        if let s = value as? String { return Double(s) ?? 0 }
        return 0
    }

    private func monthBounds(for date: Date) -> (start: String, end: String) {
        let calendar = Calendar.current
        let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) ?? date
        return (
            String(Int(startDate.timeIntervalSince1970 * 1000)),
            String(Int(endDate.timeIntervalSince1970 * 1000))
        )
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

        var data: [String: Any] = [:]
        if let snap = try? await walletRef.getDocumentAvailable(), snap.exists {
            data = snap.data() ?? [:]
        }

        var income = Double(data["income"] as? String ?? "0") ?? 0
        var expenses = Double(data["expenses"] as? String ?? "0") ?? 0
        let delta = isDelete ? -transactionData.amount : transactionData.amount
        if transactionData.type == .income {
            income += delta
        } else {
            expenses += delta
        }

        do {
            try await walletRef.setData([
                "income": String(income),
                "expenses": String(expenses),
                "updated_at": String(Int(Date().timeIntervalSince1970 * 1000))
            ], merge: true)
        } catch {
            print("Wallet update failed: \(error)")
        }
    }
}
