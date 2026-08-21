import SwiftUI
import FirebaseAuth

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var transactionVM: TransactionViewModel
    @EnvironmentObject private var categoryVM: CategoryViewModel

    var editingTransaction: Transaction? = nil

    @State private var amount = ""
    @State private var remark = ""
    @State private var date = Date()
    @State private var isExpense = true
    @State private var selectedCategory: Category?
    @State private var showingCategoryPicker = false
    @State private var error: String?
    @State private var isLoading = false
    @State private var didPrefill = false
    @ObservedObject private var currencyStore = CurrencyStore.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Amount Card
                        VStack(spacing: 16) {
                            Picker("Type", selection: $isExpense) {
                                Text("Expenses").tag(true)
                                Text("Income").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .onChange(of: isExpense) { _, _ in
                                selectedCategory = nil
                            }
                            
                            HStack {
                                Text(currencyStore.symbol)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(isExpense ? .red : .green)
                                TextField("0.00", text: $amount)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(isExpense ? .red : .green)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                        
                        // Category and Details
                        VStack(spacing: 2) {
                            Button {
                                showingCategoryPicker = true
                            } label: {
                                HStack {
                                    if let category = selectedCategory {
                                        CategoryImageView(imageUrl: category.image, size: 24, name: category.name)
                                        Text(category.name)
                                            .foregroundColor(.primary)
                                    } else {
                                        Image(systemName: "square.grid.2x2")
                                            .foregroundColor(.accentColor)
                                        Text("Select Category")
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(UIColor.systemBackground))
                            }
                            
                            Divider()
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.accentColor)
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .labelsHidden()
                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            
                            Divider()
                            
                            TextField("Add a note", text: $remark)
                                .padding()
                                .background(Color(UIColor.systemBackground))
                        }
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                        
                        // Save Button
                        Button {
                            saveTransaction()
                        } label: {
                            Text("Save")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedCategory == nil || amount.isEmpty ? Color.gray : Color.accentColor)
                                .cornerRadius(12)
                        }
                        .disabled(selectedCategory == nil || amount.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle(editingTransaction == nil ? "Add Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                prefillIfNeeded()
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory, isExpense: isExpense)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .tint(.white)
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: {
                if let error = error {
                    Text(error)
                }
            }
        }
    }
    
    private func prefillIfNeeded() {
        guard !didPrefill, let editing = editingTransaction else { return }
        didPrefill = true
        amount = String(editing.amount)
        remark = editing.remark ?? ""
        date = editing.date
        isExpense = editing.type == .expenses
        let source = isExpense ? categoryVM.expenseCategories : categoryVM.incomeCategories
        selectedCategory = source.first { $0.name == editing.category }
    }

    private func saveTransaction() {
        guard let category = selectedCategory,
              let amountDouble = Double(amount),
              let userId = Auth.auth().currentUser?.uid else {
            error = "Invalid input"
            return
        }

        isLoading = true

        let transaction = Transaction(
            id: editingTransaction?.id ?? UUID().uuidString,
            documentId: editingTransaction?.documentId,
            userId: userId,
            amount: amountDouble,
            type: isExpense ? .expenses : .income,
            category: category.name,
            remark: remark.isEmpty ? nil : remark,
            date: date
        )

        Task {
            do {
                if let original = editingTransaction {
                    try await transactionVM.updateTransaction(original: original, updated: transaction)
                } else {
                    try await transactionVM.addTransaction(transaction)
                }
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = isOfflineError(error) ? "Saved. Will sync when online." : error.localizedDescription
                    if isOfflineError(error) {
                        dismiss()
                    } else {
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

struct CategoryPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @Binding var selectedCategory: Category?
    let isExpense: Bool
    @State private var searchText = ""
    @State private var isReordering = false
    @State private var showingEditor = false
    @State private var editingCategory: Category?
    @State private var hideTarget: Category?

    var categories: [Category] {
        let source = isExpense ? categoryVM.expenseCategories : categoryVM.incomeCategories
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty { return source }
        return source.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var canReorder: Bool {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            List {
                if categories.isEmpty {
                    Text(searchText.isEmpty ? "No categories yet" : "No category found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(categories) { category in
                        Button {
                            guard !isReordering else { return }
                            selectedCategory = category
                            dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                CategoryImageView(imageUrl: category.image, size: 40, name: category.name)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(category.name)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    if category.isPersonal {
                                        Text("Yours")
                                            .font(.caption2)
                                            .foregroundColor(.accentColor)
                                    }
                                }

                                Spacer()

                                if category.id == selectedCategory?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .contextMenu {
                            if category.isPersonal {
                                Button("Rename") {
                                    editingCategory = category
                                    showingEditor = true
                                }
                                Button("Hide", role: .destructive) {
                                    hideTarget = category
                                }
                            }
                        }
                    }
                    .onMove(perform: canReorder && isReordering ? move : nil)
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search category")
            .environment(\.editMode, .constant(isReordering && canReorder ? .active : .inactive))
            .onChange(of: searchText) { _, newValue in
                if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    isReordering = false
                }
            }
            .navigationTitle(isExpense ? "Expense Categories" : "Income Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if canReorder {
                        Button(isReordering ? "Done" : "Reorder") {
                            isReordering.toggle()
                        }
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Add") {
                        editingCategory = nil
                        showingEditor = true
                    }
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                PersonalCategoryEditorView(
                    isExpense: isExpense,
                    existing: editingCategory
                )
                .environmentObject(categoryVM)
            }
            .alert("Hide this category?", isPresented: Binding(
                get: { hideTarget != nil },
                set: { if !$0 { hideTarget = nil } }
            )) {
                Button("Cancel", role: .cancel) { hideTarget = nil }
                Button("Hide", role: .destructive) {
                    if let hideTarget {
                        categoryVM.hidePersonal(category: hideTarget) { _ in }
                    }
                    hideTarget = nil
                }
            } message: {
                Text("Existing transactions keep the same name.")
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        categoryVM.reorder(from: source, to: destination, isExpense: isExpense)
    }
}

private struct PersonalCategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var categoryVM: CategoryViewModel
    let isExpense: Bool
    let existing: Category?

    @State private var name: String = ""
    @State private var selectedImage: String = ""
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                TextField("Category name", text: $name)
                Section("Icon (optional)") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            iconCell(path: "", label: "A")
                            ForEach(categoryVM.catalogImages(isExpense: isExpense), id: \.self) { path in
                                iconCell(path: path, label: nil)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                if let error {
                    Text(error).foregroundColor(.red).font(.footnote)
                }
            }
            .navigationTitle(existing == nil ? "Add category" : "Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                if let existing {
                    name = existing.name
                    selectedImage = existing.image
                }
            }
        }
    }

    private func iconCell(path: String, label: String?) -> some View {
        Button {
            selectedImage = path
        } label: {
            CategoryImageView(imageUrl: path, size: 44, name: label ?? name)
                .opacity(selectedImage == path ? 1 : 0.45)
        }
        .buttonStyle(.plain)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            error = "Enter a name"
            return
        }
        if categoryVM.hasDuplicateName(trimmed, isExpense: isExpense, exceptId: existing?.id) {
            error = "You already have this category"
            return
        }
        if let existing {
            categoryVM.renamePersonal(category: existing, name: trimmed) { ok in
                if ok { dismiss() } else { error = "Could not save category" }
            }
        } else {
            categoryVM.addPersonal(name: trimmed, image: selectedImage, isExpense: isExpense) { ok in
                if ok { dismiss() } else { error = "Could not save category" }
            }
        }
    }
}

struct AddTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddTransactionView()
            .environmentObject(TransactionViewModel())
            .environmentObject(CategoryViewModel())
    }
} 
