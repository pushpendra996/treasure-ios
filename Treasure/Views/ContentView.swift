import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @ObservedObject private var currencyStore = CurrencyStore.shared
    @ObservedObject private var languageStore = LanguageStore.shared
    @ObservedObject private var sharingDeepLink = SharingDeepLinkStore.shared
    @State private var showingUserDetails = false
    @State private var openedSharingGroupId: String?

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
                FcmTokenRegistrar.requestPermissionAndRegister()
                Task { await authVM.fetchUserData() }
            }
        }
        .onChange(of: authVM.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                FcmTokenRegistrar.requestPermissionAndRegister()
                if ExpenseReminderScheduler.isEnabled {
                    ExpenseReminderScheduler.requestAndSchedule()
                }
                if let groupId = sharingDeepLink.pendingGroupId, !groupId.isEmpty {
                    openedSharingGroupId = SharingDeepLinkStore.shared.consume()
                }
            }
        }
        .onChange(of: sharingDeepLink.pendingGroupId) { _, groupId in
            guard authVM.isAuthenticated, let groupId, !groupId.isEmpty else { return }
            openedSharingGroupId = SharingDeepLinkStore.shared.consume()
        }
        .fullScreenCover(item: Binding(
            get: { openedSharingGroupId.map { SharingGroupDeepLink($0) } },
            set: { openedSharingGroupId = $0?.id }
        )) { link in
            NavigationView {
                ExpenseSharingGroupDetailView(groupId: link.id, title: L10n.string("hint_expense_sharing"))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(L10n.string("hint_done")) { openedSharingGroupId = nil }
                        }
                    }
            }
            .navigationViewStyle(.stack)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private struct SharingGroupDeepLink: Identifiable {
    let id: String
    init(_ id: String) { self.id = id }
}
