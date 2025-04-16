import SwiftUI

struct MainTabView: View {
    @StateObject private var transactionVM = TransactionViewModel()
    @StateObject private var categoryVM = CategoryViewModel()
    @StateObject private var walletVM = WalletViewModel()
    
    var body: some View {
        TabView {
            TransactionListView()
                .environmentObject(transactionVM)
                .environmentObject(categoryVM)
                .environmentObject(walletVM)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            
            ReportView()
                .environmentObject(transactionVM)
                .environmentObject(categoryVM)
                .environmentObject(walletVM)
                .tabItem {
                    Label("Reports", systemImage: "chart.pie")
                }
            
            ProfileView()
                .environmentObject(walletVM)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .task {
            await transactionVM.fetchTransactions()
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 