import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ReportViewModel: ObservableObject {
    @Published var totalIncome: Double = 0
    @Published var totalExpenses: Double = 0
    @Published var monthlyData: [String: (income: Double, expenses: Double)] = [:]
    @Published var expensesByCategory: [String: Double] = [:]
    @Published var incomeByCategory: [String: Double] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    
    func loadData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        self.isLoading = true
        
        do {
            let year = Calendar.current.component(.year, from: Date())
            
            let snapshot = try await db.collection("transaction")
                .document(userId)
                .collection(String(year))
                .getDocuments()
            
            var newMonthlyData: [String: (income: Double, expenses: Double)] = [:]
            var newExpensesByCategory: [String: Double] = [:]
            var newIncomeByCategory: [String: Double] = [:]
            var newTotalIncome: Double = 0
            var newTotalExpenses: Double = 0
            
            for document in snapshot.documents {
                guard let transaction = Transaction(document: document) else { continue }
                
                let month = Calendar.current.component(.month, from: transaction.date)
                let monthString = String(format: "%02d", month)
                let amount = transaction.amount
                
                // Update monthly data
                var monthData = newMonthlyData[monthString] ?? (income: 0, expenses: 0)
                if transaction.type == .income {
                    monthData.income += amount
                    newTotalIncome += amount
                    
                    // Update income by category
                    newIncomeByCategory[transaction.category, default: 0] += amount
                } else {
                    monthData.expenses += amount
                    newTotalExpenses += amount
                    
                    // Update expenses by category
                    newExpensesByCategory[transaction.category, default: 0] += amount
                }
                newMonthlyData[monthString] = monthData
            }
            
            // Update all @Published properties at once on the main actor
            self.monthlyData = newMonthlyData
            self.expensesByCategory = newExpensesByCategory
            self.incomeByCategory = newIncomeByCategory
            self.totalIncome = newTotalIncome
            self.totalExpenses = newTotalExpenses
            self.isLoading = false
            
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
} 