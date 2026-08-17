import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @ObservedObject private var currencyStore = CurrencyStore.shared
    @State private var showingUserDetails = false
    
    var body: some View {
        Group {
            if authVM.isAuthenticated {
                TabView {
                    TransactionListView()
                        .tabItem {
                            Label("Transactions", systemImage: "list.bullet")
                        }
                    
                    NavigationView {
                        ReportView()
                    }
                    .navigationViewStyle(.stack)
                    .tabItem {
                        Label("Report", systemImage: "chart.pie")
                    }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                .id(currencyStore.code)
            } else {
                NavigationView {
                    LoginView()
                }
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
                ExpenseReminderScheduler.requestAndSchedule()
                Task { await authVM.fetchUserData() }
            }
        }
        .onChange(of: authVM.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
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