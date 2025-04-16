import Foundation
import FirebaseFirestore

class CategoryViewModel: ObservableObject {
    @Published var expenseCategories: [Category] = []
    @Published var incomeCategories: [Category] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var expenseListener: ListenerRegistration?
    private var incomeListener: ListenerRegistration?
    
    init() {
        setupListeners()
    }
    
    deinit {
        expenseListener?.remove()
        incomeListener?.remove()
    }
    
    private func setupListeners() {
        isLoading = true
        
        // Listen to expense categories
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
                        print("Processing expense category: \(data["category_name"] ?? "unknown")")
                        print("- category_type: \(data["category_type"] ?? "missing")")
                        print("- category_order type: \(type(of: data["category_order"] ?? "missing"))")
                        print("- category_order value: \(data["category_order"] ?? "missing")")
                        
                        if let category = Category(document: document) {
                            print("Successfully parsed expense category: \(category.name)")
                            return category
                        } else {
                            print("Failed to parse expense category with data: \(data)")
                            return nil
                        }
                    }
                    print("Successfully parsed \(categories.count) expense categories")
                    self.expenseCategories = categories
                }
                
                self.isLoading = false
            }
        
        // Listen to income categories
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
                        if let category = Category(document: document) {
                            print("Successfully parsed income category: \(category.name)")
                            return category
                        } else {
                            print("Failed to parse income category with data: \(data)")
                            return nil
                        }
                    }
                    print("Successfully parsed \(categories.count) income categories")
                    self.incomeCategories = categories
                }
                
                self.isLoading = false
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
} 