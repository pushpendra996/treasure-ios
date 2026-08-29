import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @ObservedObject private var currencyStore = CurrencyStore.shared
    @ObservedObject private var languageStore = LanguageStore.shared
    @State private var showingUserDetails = false

    var body: some View {
        Group {
            if !languageStore.hasSelected {
                NavigationView {
                    LanguagePickerView(onboarding: true)
                }
                .navigationViewStyle(.stack)
            } else if authVM.isAuthenticated {
                TabView {
                    TransactionListView()
                        .tabItem {
                            Label(L10n.string("hint_all_transactions"), systemImage: "list.bullet")
                        }

                    NavigationView {
                        ReportView()
                    }
                    .navigationViewStyle(.stack)
                    .tabItem {
                        Label(L10n.string("hint_report"), systemImage: "chart.pie")
                    }

                    MenuView()
                        .tabItem {
                            Label(L10n.string("hint_menu"), systemImage: "square.grid.2x2")
                        }
                }
                .id("\(currencyStore.code)-\(languageStore.code)")
            } else {
                NavigationView {
                    LoginView()
                }
                .navigationViewStyle(.stack)
            }
        }
        .fullScreenCover(isPresented: $showingUserDetails) {
            NavigationView {
                UserDetailsView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .authenticationSuccessful)) { _ in
            Task {
                await authVM.fetchUserData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openUserDetails)) { _ in
            showingUserDetails = true
        }
        .onAppear {
            if authVM.isAuthenticated {
                if ExpenseReminderScheduler.isEnabled {
                    ExpenseReminderScheduler.requestAndSchedule()
                }
                Task { await authVM.fetchUserData() }
            }
        }
        .onChange(of: authVM.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated, ExpenseReminderScheduler.isEnabled {
                ExpenseReminderScheduler.requestAndSchedule()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
