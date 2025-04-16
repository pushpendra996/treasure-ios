import SwiftUI
import FirebaseAuth

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var transactionVM: TransactionViewModel
    @EnvironmentObject private var categoryVM: CategoryViewModel
    
    @State private var amount = ""
    @State private var remark = ""
    @State private var date = Date()
    @State private var isExpense = true
    @State private var selectedCategory: Category?
    @State private var showingCategoryPicker = false
    @State private var error: String?
    @State private var isLoading = false
    
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
                                Text("₹")
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
                                        CategoryImageView(imageUrl: category.image, size: 24)
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
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory, isExpense: isExpense)
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
    
    private func saveTransaction() {
        guard let category = selectedCategory,
              let amountDouble = Double(amount),
              let userId = Auth.auth().currentUser?.uid else {
            error = "Invalid input"
            return
        }
        
        isLoading = true
        
        let transaction = Transaction(
            userId: userId,
            amount: amountDouble,
            type: isExpense ? .expenses : .income,
            category: category.name,
            remark: remark.isEmpty ? nil : remark,
            date: date
        )
        
        Task {
            do {
                try await transactionVM.addTransaction(transaction)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
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
    
    var categories: [Category] {
        isExpense ? categoryVM.expenseCategories : categoryVM.incomeCategories
    }
    
    var body: some View {
        NavigationView {
            List {
                if categories.isEmpty {
                    Text("Loading categories...")
                } else {
                    ForEach(categories) { category in
                        Button {
                            selectedCategory = category
                            dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                CategoryImageView(imageUrl: category.image, size: 40)
                                
                                Text(category.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if category.id == selectedCategory?.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(isExpense ? "Expense Categories" : "Income Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
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
