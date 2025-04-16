import SwiftUI

class AppViewModel: ObservableObject {
    @Published var transactionVM: TransactionViewModel
    @Published var categoryVM: CategoryViewModel
    @Published var walletVM: WalletViewModel
    
    init() {
        self.transactionVM = TransactionViewModel()
        self.categoryVM = CategoryViewModel()
        self.walletVM = WalletViewModel()
    }
} 