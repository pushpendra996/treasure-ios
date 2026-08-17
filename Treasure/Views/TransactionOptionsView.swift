import SwiftUI

struct TransactionOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var transactionVM: TransactionViewModel
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @ObservedObject private var currencyStore = CurrencyStore.shared
    
    let transaction: Transaction
    @State private var showingDeleteAlert = false
    @State private var showingEdit = false
    @State private var error: String?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        CategoryImageView(imageUrl: categoryVM.getCategoryImage(for: transaction.category), size: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.category)
                                .font(.headline)
                            
                            if let remark = transaction.remark {
                                Text(remark)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(transaction.date.formatted(date: .long, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(formattedAmount(transaction.amount, fractionDigits: 2))
                            .font(.headline)
                            .foregroundColor(transaction.type == .income ? .green : .red)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit Transaction", systemImage: "pencil")
                    }
                    
                    Button {
                        // TODO: Implement duplicate functionality
                        dismiss()
                    } label: {
                        Label("Duplicate Transaction", systemImage: "plus.square.on.square")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Transaction", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Transaction", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTransaction()
                }
            } message: {
                Text("Are you sure you want to delete this transaction? This action cannot be undone.")
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error)
                }
            }
            .sheet(isPresented: $showingEdit) {
                AddTransactionView(editingTransaction: transaction)
                    .environmentObject(transactionVM)
                    .environmentObject(categoryVM)
            }
            .onChange(of: showingEdit) { _, isShowing in
                if !isShowing {
                    dismiss()
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private func deleteTransaction() {
        isLoading = true
        
        Task {
            do {
                try await transactionVM.deleteTransaction(transaction)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                if isOfflineError(error) {
                    await MainActor.run { dismiss() }
                } else {
                    await MainActor.run {
                        self.error = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    TransactionOptionsView(transaction: Transaction(
        userId: "preview",
        amount: 99.99,
        type: .expenses,
        category: "Food",
        remark: "Lunch",
        date: Date()
    ))
    .environmentObject(TransactionViewModel())
    .environmentObject(CategoryViewModel())
} 