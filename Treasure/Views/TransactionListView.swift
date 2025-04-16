import SwiftUI

struct TransactionListView: View {
    @EnvironmentObject private var transactionVM: TransactionViewModel
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @State private var showingAddTransaction = false
    @State private var selectedTransaction: Transaction?
    @State private var showingOptions = false
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(transactionVM.transactions) { transaction in
                        TransactionRow(transaction: transaction)
                            .onTapGesture {
                                selectedTransaction = transaction
                                showingOptions = true
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await transactionVM.fetchTransactions()
                }
                
                if transactionVM.isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
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
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @EnvironmentObject private var categoryVM: CategoryViewModel
    
    var body: some View {
        HStack {
            CategoryImageView(imageUrl: categoryVM.getCategoryImage(for: transaction.category), size: 40)
            
            VStack(alignment: .leading) {
                Text(transaction.category)
                    .font(.headline)
                if let remark = transaction.remark {
                    Text(remark)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(String(format: "%.2f", transaction.amount))
                    .font(.headline)
                    .foregroundColor(transaction.type == .income ? .green : .red)
                
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
