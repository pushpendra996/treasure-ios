import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var showingUserDetails = false
    
    var body: some View {
        Group {
            if authVM.isAuthenticated {
                TabView {
                    TransactionListView()
                        .tabItem {
                            Label("Transactions", systemImage: "list.bullet")
                        }
                    
                    ReportView()
                        .tabItem {
                            Label("Report", systemImage: "chart.pie")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 