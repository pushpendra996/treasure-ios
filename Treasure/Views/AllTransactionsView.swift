import SwiftUI

struct AllTransactionsView: View {
    @StateObject private var viewModel = AllTransactionsViewModel()
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @State private var selectedTransaction: Transaction?
    @State private var showingOptions = false

    var body: some View {
        ZStack {
            List {
                ForEach(viewModel.groups) { group in
                    Section(group.title) {
                        ForEach(group.items) { transaction in
                            TransactionRow(transaction: transaction)
                                .onTapGesture {
                                    selectedTransaction = transaction
                                    showingOptions = true
                                }
                                .onAppear {
                                    if transaction.id == viewModel.groups.last?.items.last?.id {
                                        Task { await viewModel.loadMore() }
                                    }
                                }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                await viewModel.reload()
            }

            if viewModel.groups.isEmpty && !viewModel.isLoading {
                Text(L10n.string("hint_no_transactions_yet"))
                    .foregroundColor(.secondary)
            }

            if viewModel.isLoading && viewModel.groups.isEmpty {
                ProgressView()
            }
        }
        .navigationTitle("All transactions")
        .task {
            if viewModel.groups.isEmpty {
                await viewModel.reload()
            }
        }
        .sheet(isPresented: $showingOptions) {
            if let transaction = selectedTransaction {
                TransactionOptionsView(transaction: transaction)
            }
        }
    }
}
