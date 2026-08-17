import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AllTransactionsViewModel: ObservableObject {
    struct MonthGroup: Identifiable {
        var id: String { title }
        let title: String
        var items: [Transaction]
    }

    @Published var groups: [MonthGroup] = []
    @Published var isLoading = false
    @Published var hasMore = true
    @Published var error: String?

    private let db = Firestore.firestore()
    private let limit = 20
    private var lastDocument: DocumentSnapshot?
    private var queryYear = Calendar.current.component(.year, from: Date())
    private let minYear = 2020
    private var transactions: [Transaction] = []

    func reload() async {
        lastDocument = nil
        queryYear = Calendar.current.component(.year, from: Date())
        transactions = []
        groups = []
        hasMore = true
        await loadMore()
    }

    func loadMore() async {
        guard !isLoading, hasMore else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        await fetchPage(userId: userId)
        isLoading = false
    }

    private func fetchPage(userId: String) async {
        while queryYear >= minYear {
            do {
                var query: Query = db.collection("transaction")
                    .document(userId)
                    .collection(String(queryYear))
                    .order(by: "transaction_date", descending: true)
                    .limit(to: limit)
                if let lastDocument {
                    query = query.start(afterDocument: lastDocument)
                }
                let snapshot = try await query.getDocumentsAvailable()
                if snapshot.documents.isEmpty {
                    queryYear -= 1
                    lastDocument = nil
                    continue
                }
                let page = snapshot.documents.compactMap { Transaction(document: $0) }
                transactions.append(contentsOf: page)
                rebuildGroups()
                if page.count < limit {
                    queryYear -= 1
                    lastDocument = nil
                    hasMore = queryYear >= minYear
                } else {
                    lastDocument = snapshot.documents.last
                    hasMore = true
                }
                return
            } catch {
                self.error = error.localizedDescription
                hasMore = false
                return
            }
        }
        hasMore = false
    }

    private func rebuildGroups() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var next: [MonthGroup] = []
        for txn in transactions {
            let title = formatter.string(from: txn.date)
            if let last = next.indices.last, next[last].title == title {
                next[last].items.append(txn)
            } else {
                next.append(MonthGroup(title: title, items: [txn]))
            }
        }
        groups = next
    }
}
