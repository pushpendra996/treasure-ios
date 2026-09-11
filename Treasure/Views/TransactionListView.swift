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
                        Text(NetworkMonitor.shared.isConnected ? L10n.string("hint_no_transactions_month") : L10n.string("hint_no_cached_month"))
                            .foregroundColor(.secondary)
                    }

                    if transactionVM.isLoading && transactionVM.transactions.isEmpty {
                        ProgressView()
                    }
                }
            }
            .id(currencyStore.code)
            .navigationTitle(L10n.string("hint_all_transactions"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: ExpenseSharingView()) {
                        Image(systemName: "person.3.sequence")
                            .imageScale(.large)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        RewardedAds.showThenForAddTransaction {
                            showingAddTransaction = true
                        }
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
                InAppReviewHelper.maybePrompt(source: .transactionList)
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
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        return LazyVGrid(columns: columns, spacing: 12) {
            summaryCard(
                title: L10n.string("hint_expense"),
                amount: transactionVM.monthExpenses,
                background: TreasureTheme.summaryExpenseBg,
                icon: "arrow.down",
                iconColor: TreasureTheme.expense
            )
            summaryCard(
                title: L10n.string("hint_income"),
                amount: transactionVM.monthIncome,
                background: TreasureTheme.summaryIncomeBg,
                icon: "arrow.up",
                iconColor: TreasureTheme.income
            )
            summaryCard(
                title: L10n.string("hint_previous_month_saving"),
                amount: transactionVM.previousMonthSaving,
                background: TreasureTheme.summarySavingBg,
                icon: "banknote",
                iconColor: TreasureTheme.saving
            )
            summaryCard(
                title: L10n.string("hint_balance"),
                amount: transactionVM.monthIncome - transactionVM.monthExpenses,
                background: TreasureTheme.summaryBalanceBg,
                icon: "wallet.pass",
                iconColor: TreasureTheme.purple
            )
        }
        .padding(.bottom, 8)
    }

    private func summaryCard(
        title: String,
        amount: Double,
        background: Color,
        icon: String,
        iconColor: Color
    ) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(iconColor.opacity(0.18)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(formattedSummaryAmount(amount))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(background)
                .shadow(color: Color.black.opacity(0.06), radius: 3, y: 1)
        )
    }

    private func formattedSummaryAmount(_ value: Double) -> String {
        let hasFraction = abs(value - value.rounded()) > 0.0005
        return formattedAmount(value, fractionDigits: hasFraction ? 2 : 0)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @ObservedObject private var currencyStore = CurrencyStore.shared

    var body: some View {
        HStack {
            CategoryImageView(imageUrl: categoryVM.getCategoryImage(for: transaction.category), size: 40, name: transaction.category)

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
