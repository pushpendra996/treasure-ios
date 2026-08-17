import Foundation
import FirebaseAuth
import FirebaseFirestore

class CategoryViewModel: ObservableObject {
    @Published var expenseCategories: [Category] = []
    @Published var incomeCategories: [Category] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var expenseListener: ListenerRegistration?
    private var incomeListener: ListenerRegistration?
    private var userListener: ListenerRegistration?
    private var rawExpenseCategories: [Category] = []
    private var rawIncomeCategories: [Category] = []
    private var expenseOrder: [String] = []
    private var incomeOrder: [String] = []
    
    init() {
        setupListeners()
    }
    
    deinit {
        expenseListener?.remove()
        incomeListener?.remove()
        userListener?.remove()
    }
    
    private func setupListeners() {
        isLoading = true
        listenUserOrder()
        
        expenseListener = db.collection("category")
            .whereField("category_type", isEqualTo: "expenses")
            .order(by: "category_order")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching expense categories: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                    return
                }
                
                if let documents = snapshot?.documents {
                    print("Found \(documents.count) expense documents")
                    let categories = documents.compactMap { document -> Category? in
                        let data = document.data()
                        if let active = data["active"] as? Bool, active == false {
                            return nil
                        }
                        return Category(document: document)
                    }
                    print("Successfully parsed \(categories.count) expense categories")
                    self.rawExpenseCategories = categories
                    self.expenseCategories = self.applyOrder(categories, ids: self.expenseOrder)
                    CategoryIconStore.prefetch(paths: categories.map(\.image))
                }
                
                self.isLoading = false
            }
        
        incomeListener = db.collection("category")
            .whereField("category_type", isEqualTo: "income")
            .order(by: "category_order")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching income categories: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                    return
                }
                
                if let documents = snapshot?.documents {
                    print("Found \(documents.count) income documents")
                    let categories = documents.compactMap { document -> Category? in
                        let data = document.data()
                        if let active = data["active"] as? Bool, active == false {
                            return nil
                        }
                        return Category(document: document)
                    }
                    print("Successfully parsed \(categories.count) income categories")
                    self.rawIncomeCategories = categories
                    self.incomeCategories = self.applyOrder(categories, ids: self.incomeOrder)
                    CategoryIconStore.prefetch(paths: categories.map(\.image))
                }
                
                self.isLoading = false
            }
    }
    
    func reorder(from source: IndexSet, to destination: Int, isExpense: Bool) {
        if isExpense {
            expenseCategories.move(fromOffsets: source, toOffset: destination)
            expenseOrder = expenseCategories.map(\.id)
            persistOrder(ids: expenseOrder, field: "expense_category_order")
        } else {
            incomeCategories.move(fromOffsets: source, toOffset: destination)
            incomeOrder = incomeCategories.map(\.id)
            persistOrder(ids: incomeOrder, field: "income_category_order")
        }
    }
    
    func getCategoryImage(for categoryName: String) -> String {
        if let category = expenseCategories.first(where: { $0.name == categoryName }) {
            return category.image
        }
        if let category = incomeCategories.first(where: { $0.name == categoryName }) {
            return category.image
        }
        return "default_category"
    }
    
    private func listenUserOrder() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        userListener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self else { return }
            let data = snapshot?.data() ?? [:]
            self.expenseOrder = data["expense_category_order"] as? [String] ?? []
            self.incomeOrder = data["income_category_order"] as? [String] ?? []
            self.expenseCategories = self.applyOrder(self.rawExpenseCategories, ids: self.expenseOrder)
            self.incomeCategories = self.applyOrder(self.rawIncomeCategories, ids: self.incomeOrder)
        }
    }
    
    private func persistOrder(ids: [String], field: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).setData([field: ids], merge: true)
    }
    
    private func applyOrder(_ categories: [Category], ids: [String]) -> [Category] {
        guard !ids.isEmpty else { return categories }
        var byId = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        var result: [Category] = []
        result.reserveCapacity(categories.count)
        for id in ids {
            if let category = byId.removeValue(forKey: id) {
                result.append(category)
            }
        }
        for category in categories where byId[category.id] != nil {
            result.append(category)
        }
        return result
    }
}
