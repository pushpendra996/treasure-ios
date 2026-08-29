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
                        CategoryImageView(imageUrl: categoryVM.getCategoryImage(for: transaction.category), size: 60, name: transaction.category)

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
                            .foregroundColor(transaction.type == .income ? TreasureTheme.income : TreasureTheme.expense)
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button {
                        showingEdit = true
                    } label: {
                        Label(L10n.string("hint_edit_transaction"), systemImage: "pencil")
                    }

                    Button {
                        duplicate()
                    } label: {
                        Label(L10n.string("hint_duplicate_transaction"), systemImage: "plus.square.on.square")
                    }

                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label(L10n.string("hint_delete_transaction"), systemImage: "trash")
                    }
                }
            }
            .navigationTitle(L10n.string("hint_transaction_details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string("hint_done")) {
                        dismiss()
                    }
                }
            }
            .alert(L10n.string("hint_delete_transaction"), isPresented: $showingDeleteAlert) {
                Button(L10n.string("hint_cancel"), role: .cancel) { }
                Button(L10n.string("hint_delete"), role: .destructive) {
                    deleteTransaction()
                }
            } message: {
                Text(L10n.string("hint_delete_transaction_warning"))
            }
            .alert(L10n.string("hint_error"), isPresented: .constant(error != nil)) {
                Button(L10n.string("hint_ok")) {
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

    private func duplicate() {
        isLoading = true
        Task {
            do {
                try await transactionVM.duplicateTransaction(transaction)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
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
