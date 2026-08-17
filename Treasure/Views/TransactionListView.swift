import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject private var transactionVM: TransactionViewModel
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @ObservedObject private var currencyStore = CurrencyStore.shared
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?
    @State private var showingOptions = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                OfflineBanner()
                monthSelector
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                monthSummary
                    .padding(.horizontal)

                ZStack {
                    List {
                        ForEach(transactionVM.transactions) { transaction in
                            TransactionRow(transaction: transaction)
                                .onTapGesture {
                                    selectedTransaction = transaction
                                    showingOptions = true
                                }
                                .onAppear {
                                    if transaction.id == transactionVM.transactions.last?.id,
                                       transactionVM.hasMore,
                                       !transactionVM.isLoading {
                                        Task {
                                            await transactionVM.fetchTransactions(reset: false)
                                        }
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await transactionVM.fetchTransactions(reset: true)
                    }

                    if transactionVM.transactions.isEmpty && !transactionVM.isLoading {
                        Text(NetworkMonitor.shared.isConnected ? "No transactions this month" : "No cached data for this month")
                            .foregroundColor(.secondary)
                    }

                    if transactionVM.isLoading && transactionVM.transactions.isEmpty {
                        ProgressView()
                    }
                }
            }
            .id(currencyStore.code)
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: ExpenseSharingView()) {
                        Image(systemName: "person.3.sequence")
                            .imageScale(.large)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .sheet(isPresented: $showingOptions) {
                if let transaction = selectedTransaction {
                    TransactionOptionsView(transaction: transaction)
                }
            }
            .task {
                await transactionVM.fetchTransactions(reset: true)
            }
            .onChange(of: transactionVM.selectedMonth) { _, _ in
                Task {
                    await transactionVM.fetchTransactions(reset: true)
                }
            }
        }
    }

    private var monthSelector: some View {
        HStack {
            Button {
                transactionVM.shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .padding(8)
                    .background(Circle().fill(Color(.systemGray5)))
            }
            Text(transactionVM.monthLabel)
                .font(.headline)
                .frame(maxWidth: .infinity)
            Button {
                transactionVM.shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .padding(8)
                    .background(Circle().fill(Color(.systemGray5)))
            }
        }
        .foregroundColor(.primary)
    }

    private var monthSummary: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                summaryPill(
                    title: "Expense",
                    amount: transactionVM.monthExpenses,
                    color: .red,
                    icon: "arrow.down"
                )
                summaryPill(
                    title: "Income",
                    amount: transactionVM.monthIncome,
                    color: .green,
                    icon: "arrow.up"
                )
            }
            Text("Balance: \(formattedAmount(transactionVM.monthIncome - transactionVM.monthExpenses))")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
        }
        .padding(.bottom, 6)
    }

    private func summaryPill(title: String, amount: Double, color: Color, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.white.opacity(0.22)))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Text(formattedAmount(amount))
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color)
        .clipShape(Capsule())
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @ObservedObject private var currencyStore = CurrencyStore.shared

    var body: some View {
        HStack {
            CategoryImageView(imageUrl: categoryVM.getCategoryImage(for: transaction.category), size: 40)

            VStack(alignment: .leading) {
                Text(transaction.category)
                    .font(.headline)
                if let remark = transaction.remark, !remark.isEmpty {
                    Text(remark)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(formattedAmount(transaction.amount))
                        .font(.headline)
                        .foregroundColor(transaction.type == .income ? .green : .red)
                    Image(systemName: transaction.type == .income ? "arrow.up" : "arrow.down")
                        .font(.caption.weight(.bold))
                        .foregroundColor(transaction.type == .income ? .green : .red)
                }

                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TransactionListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionListView()
            .environmentObject(TransactionViewModel())
            .environmentObject(CategoryViewModel())
    }
}
