import Foundation
import FirebaseAuth
import FirebaseFirestore

class CategoryViewModel: ObservableObject {
    @Published var expenseCategories: [Category] = []
    @Published var incomeCategories: [Category] = []
    @Published var isLoading = false
    @Published var error: String?

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var userListener: ListenerRegistration?

    private var adminExpenses: [Category] = []
    private var userExpenses: [Category] = []
    private var adminIncome: [Category] = []
    private var userIncome: [Category] = []
    private var rawExpenseCategories: [Category] = []
    private var rawIncomeCategories: [Category] = []
    private var expenseOrder: [String] = []
    private var incomeOrder: [String] = []

    init() {
        setupListeners()
    }

    deinit {
        listeners.forEach { $0.remove() }
        userListener?.remove()
    }

    private func setupListeners() {
        isLoading = true
        listenUserOrder()

        listenMerged(type: "expenses", isExpense: true)
        listenMerged(type: "income", isExpense: false)
    }

    private func listenMerged(type: String, isExpense: Bool) {
        let admin = db.collection("category")
            .whereField("category_type", isEqualTo: type)
            .whereField("created_by", isEqualTo: "admin")
            .order(by: "category_order")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching \(type) admin categories: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                    return
                }
                let parsed = self.parse(snapshot)
                if isExpense {
                    self.adminExpenses = parsed
                } else {
                    self.adminIncome = parsed
                }
                self.publishMerged()
                self.isLoading = false
            }
        listeners.append(admin)

        guard let uid = Auth.auth().currentUser?.uid else { return }
        let personal = db.collection("category")
            .whereField("category_type", isEqualTo: type)
            .whereField("created_by", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching \(type) personal categories: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                    return
                }
                let parsed = self.parse(snapshot).sorted { $0.order < $1.order }
                if isExpense {
                    self.userExpenses = parsed
                } else {
                    self.userIncome = parsed
                }
                self.publishMerged()
            }
        listeners.append(personal)
    }

    private func parse(_ snapshot: QuerySnapshot?) -> [Category] {
        guard let documents = snapshot?.documents else { return [] }
        return documents.compactMap { Category(document: $0) }
    }

    private func publishMerged() {
        rawExpenseCategories = adminExpenses + userExpenses
        rawIncomeCategories = adminIncome + userIncome
        expenseCategories = applyOrder(rawExpenseCategories, ids: expenseOrder)
        incomeCategories = applyOrder(rawIncomeCategories, ids: incomeOrder)
        CategoryIconStore.prefetch(paths: (expenseCategories + incomeCategories).map(\.image))
    }

    func catalogImages(isExpense: Bool) -> [String] {
        let source = isExpense ? expenseCategories : incomeCategories
        var seen = Set<String>()
        var out: [String] = []
        for item in source {
            let path = item.image
            if path.isEmpty || seen.contains(path) { continue }
            seen.insert(path)
            out.append(path)
        }
        return out
    }

    func hasDuplicateName(_ name: String, isExpense: Bool, exceptId: String? = nil) -> Bool {
        let needle = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return false }
        let source = isExpense ? expenseCategories : incomeCategories
        return source.contains { item in
            if let exceptId, item.id == exceptId { return false }
            return item.name.compare(needle, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
    }

    func addPersonal(name: String, image: String, isExpense: Bool, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !hasDuplicateName(trimmed, isExpense: isExpense) else {
            completion(false)
            return
        }
        let source = isExpense ? expenseCategories : incomeCategories
        let order = (source.map(\.order).max() ?? 0) + 1
        db.collection("category").addDocument(data: [
            "category_name": trimmed,
            "category_image": image,
            "category_type": isExpense ? "expenses" : "income",
            "category_order": order,
            "active": true,
            "created_by": uid,
            "createdAt": Timestamp(date: Date())
        ]) { error in
            completion(error == nil)
        }
    }

    func renamePersonal(category: Category, name: String, completion: @escaping (Bool) -> Void) {
        guard category.isPersonal else {
            completion(false)
            return
        }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let isExpense = category.type == .expenses
        guard !trimmed.isEmpty, !hasDuplicateName(trimmed, isExpense: isExpense, exceptId: category.id) else {
            completion(false)
            return
        }
        db.collection("category").document(category.id).updateData([
            "category_name": trimmed,
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            completion(error == nil)
        }
    }

    func hidePersonal(category: Category, completion: @escaping (Bool) -> Void) {
        guard category.isPersonal else {
            completion(false)
            return
        }
        db.collection("category").document(category.id).updateData([
            "active": false,
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            completion(error == nil)
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
