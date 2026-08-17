import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ReportViewModel: ObservableObject {
    enum Timeframe: String, CaseIterable {
        case year = "Year"
        case month = "Month"
    }

    @Published var totalIncome: Double = 0
    @Published var totalExpenses: Double = 0
    @Published var monthlyData: [String: (income: Double, expenses: Double)] = [:]
    @Published var expensesByCategory: [String: Double] = [:]
    @Published var incomeByCategory: [String: Double] = [:]
    @Published var isLoading = false
    @Published var error: String?
    @Published var timeframe: Timeframe = .year
    @Published var selectedDate: Date = Date()

    private let db = Firestore.firestore()

    var netBalance: Double { totalIncome - totalExpenses }

    var periodLabel: String {
        if timeframe == .month {
            return selectedDate.formatted(.dateTime.month(.wide).year())
        }
        return String(Calendar.current.component(.year, from: selectedDate))
    }

    func shiftPeriod(by value: Int) {
        let component: Calendar.Component = timeframe == .month ? .month : .year
        if let next = Calendar.current.date(byAdding: component, value: value, to: selectedDate) {
            selectedDate = next
        }
    }

    func loadData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        let year = Calendar.current.component(.year, from: selectedDate)
        let selectedMonth = Calendar.current.component(.month, from: selectedDate)
        let query = db.collection("transaction")
            .document(userId)
            .collection(String(year))

        if let cache = try? await query.getDocuments(source: .cache) {
            apply(snapshot: cache, selectedMonth: selectedMonth)
        }
        if let server = try? await query.getDocuments(source: .server) {
            apply(snapshot: server, selectedMonth: selectedMonth)
        } else if monthlyData.isEmpty,
                  let fallback = try? await query.getDocuments() {
            apply(snapshot: fallback, selectedMonth: selectedMonth)
        }
        isLoading = false
    }

    private func apply(snapshot: QuerySnapshot, selectedMonth: Int) {
        var newMonthlyData: [String: (income: Double, expenses: Double)] = [:]
        var newExpensesByCategory: [String: Double] = [:]
        var newIncomeByCategory: [String: Double] = [:]
        var newTotalIncome: Double = 0
        var newTotalExpenses: Double = 0

        for document in snapshot.documents {
            guard let transaction = Transaction(document: document) else { continue }
            let month = Calendar.current.component(.month, from: transaction.date)
            if timeframe == .month && month != selectedMonth {
                continue
            }
            let monthString = String(format: "%02d", month)
            let amount = transaction.amount
            var monthData = newMonthlyData[monthString] ?? (income: 0, expenses: 0)
            if transaction.type == .income {
                monthData.income += amount
                newTotalIncome += amount
                newIncomeByCategory[transaction.category, default: 0] += amount
            } else {
                monthData.expenses += amount
                newTotalExpenses += amount
                newExpensesByCategory[transaction.category, default: 0] += amount
            }
            newMonthlyData[monthString] = monthData
        }

        monthlyData = newMonthlyData
        expensesByCategory = newExpensesByCategory
        incomeByCategory = newIncomeByCategory
        totalIncome = newTotalIncome
        totalExpenses = newTotalExpenses
    }
}
