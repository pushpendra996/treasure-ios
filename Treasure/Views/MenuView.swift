import SwiftUI

struct MenuView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var currencyStore = CurrencyStore.shared
    @ObservedObject private var languageStore = LanguageStore.shared
    @State private var showingCurrency = false
    @State private var showingLanguage = false
    @State private var showingShare = false
    @State private var showingLogout = false
    @State private var showingDelete = false
    @State private var goReports = false
    @State private var goTransactions = false
    @State private var remindersOn = ExpenseReminderScheduler.isEnabled

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    profileCard
                    permissionCard
                    actionsCard
                    accountCard
                    if let appInfo = viewModel.appInfo {
                        Text(appInfo)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .background(TreasureTheme.screenBackground.ignoresSafeArea())
            .navigationTitle(L10n.string("hint_menu"))
            .onAppear { viewModel.onAppear() }
            .navigationDestination(isPresented: $goReports) { ReportView() }
            .navigationDestination(isPresented: $goTransactions) { AllTransactionsView() }
            .sheet(isPresented: $showingCurrency) {
                NavigationView { CurrencyPickerView() }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingLanguage) {
                NavigationView {
                    LanguagePickerView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(L10n.string("hint_done")) { showingLanguage = false }
                            }
                        }
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingShare) {
                ShareAppSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .alert(L10n.string("hint_logout"), isPresented: $showingLogout) {
                Button(L10n.string("hint_cancel"), role: .cancel) {}
                Button(L10n.string("hint_logout"), role: .destructive) { viewModel.signOut() }
            } message: {
                Text(L10n.string("hint_logout_warning"))
            }
            .alert(L10n.string("hint_delete_account"), isPresented: $showingDelete) {
                Button(L10n.string("hint_cancel"), role: .cancel) {}
                Button(L10n.string("hint_delete_account"), role: .destructive) {
                    Task { await viewModel.deleteAccount() }
                }
            } message: {
                Text(L10n.string("hint_delete_account_warning"))
            }
            .overlay {
                if viewModel.isDeleting {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity).background(.ultraThinMaterial)
                }
            }
        }
    }

    private var profileCard: some View {
        Button(action: viewModel.onTapProfile) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.greeting)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.personName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    if let phone = viewModel.personMobileNo {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "pencil")
                    .foregroundColor(TreasureTheme.purple)
                    .frame(width: 34, height: 34)
                    .background(TreasureTheme.tileBackground())
            }
            .padding(14)
            .background(menuCard)
        }
        .buttonStyle(.plain)
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.string("hint_permission_center_title"))
                .font(.subheadline.weight(.bold))
            Text(L10n.string("hint_permission_center_subtitle"))
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                menuIcon("bell")
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.string("hint_permission_alerts_short"))
                        .font(.subheadline.weight(.semibold))
                    Text(L10n.string("hint_permission_alerts_sub"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $remindersOn)
                    .labelsHidden()
                    .tint(TreasureTheme.purple)
                    .onChange(of: remindersOn) { _, on in
                        ExpenseReminderScheduler.setEnabled(on)
                    }
            }
            .padding(.top, 8)
        }
        .padding(14)
        .background(menuCard)
    }

    private var actionsCard: some View {
        VStack(spacing: 0) {
            menuButton(title: L10n.string("hint_reports"), icon: "chart.pie") {
                RewardedAds.showThen { goReports = true }
            }
            divider
            menuButton(title: L10n.string("hint_all_transactions"), icon: "list.bullet") {
                RewardedAds.showThen { goTransactions = true }
            }
            divider
            NavigationLink(destination: CommitteeView()) {
                menuRow(title: L10n.string("hint_committee"), icon: "person.3")
            }
            divider
            NavigationLink(destination: ManagePermissionsView()) {
                menuRow(title: L10n.string("hint_manage_permissions"), icon: "lock.shield")
            }
            divider
            Button { showingCurrency = true } label: {
                HStack {
                    menuRow(title: L10n.string("hint_currency"), icon: "dollarsign.circle")
                    Text(currencyStore.label)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            divider
            Button { showingLanguage = true } label: {
                HStack {
                    menuRow(title: L10n.string("hint_language"), icon: "globe")
                    Text(languageStore.nativeLabel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            divider
            Button { showingShare = true } label: {
                menuRow(title: L10n.string("hint_share_app_menu"), icon: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
        }
        .background(menuCard)
    }

    private var accountCard: some View {
        VStack(spacing: 0) {
            Button {
                if let url = URL(string: StoreLinks.privacyPolicy) {
                    UIApplication.shared.open(url)
                }
            } label: {
                menuRow(title: L10n.string("hint_privacy_policy"), icon: "hand.raised")
            }
            .buttonStyle(.plain)
            divider
            Button { showingDelete = true } label: {
                HStack {
                    menuIcon("trash")
                    Text(L10n.string("hint_delete_account"))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            divider
            Button { showingLogout = true } label: {
                HStack {
                    menuIcon("rectangle.portrait.and.arrow.right")
                    Text(L10n.string("hint_logout"))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .background(menuCard)
    }

    private var menuCard: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.systemGray6))
            .frame(height: 1)
            .padding(.leading, 60)
    }

    private func menuIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(TreasureTheme.purple)
            .frame(width: 34, height: 34)
            .background(TreasureTheme.tileBackground())
    }

    private func menuRow(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            menuIcon(icon)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func menuButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            menuRow(title: title, icon: icon)
        }
        .buttonStyle(.plain)
    }
}

struct CurrencyPickerView: View {
    @ObservedObject private var currencyStore = CurrencyStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(CurrencyStore.options) { option in
            Button {
                currencyStore.save(option.code)
                dismiss()
            } label: {
                HStack {
                    Text(option.symbol)
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.code).foregroundColor(.primary)
                        Text(option.name).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    if currencyStore.code == option.code {
                        Image(systemName: "checkmark").foregroundColor(TreasureTheme.purple)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(L10n.string("hint_currency"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ShareAppSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var message: String {
        L10n.format("hint_share_app_message", StoreLinks.shareURL)
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            Image(systemName: "square.and.arrow.up.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(TreasureTheme.purple)
            Text(L10n.string("hint_share_app_title"))
                .font(.title3.weight(.bold))
            Text(L10n.string("hint_share_app_body"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button {
                let activity = UIActivityViewController(activityItems: [message], applicationActivities: nil)
                topController()?.present(activity, animated: true)
            } label: {
                Text(L10n.string("hint_share_app_action"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TreasureTheme.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Button {
                UIPasteboard.general.string = message
                copied = true
            } label: {
                Text(copied ? L10n.string("hint_share_app_copied") : L10n.string("hint_share_app_copy"))
                    .font(.headline)
                    .foregroundColor(TreasureTheme.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(TreasureTheme.purple.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func topController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        var root = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = root?.presentedViewController { root = presented }
        return root
    }
}

struct ManagePermissionsView: View {
    @State private var statusText = ""
    @State private var remindersOn = ExpenseReminderScheduler.isEnabled

    var body: some View {
        List {
            Section {
                Text(L10n.string("hint_manage_permissions_ios_intro"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Section(L10n.string("hint_permission_alerts_short")) {
                HStack {
                    Text(statusText.isEmpty ? L10n.string("hint_loading") : statusText)
                    Spacer()
                }
                Toggle(L10n.string("hint_permission_alerts_short"), isOn: $remindersOn)
                    .tint(TreasureTheme.purple)
                    .onChange(of: remindersOn) { _, on in
                        ExpenseReminderScheduler.setEnabled(on)
                    }
                Button(L10n.string("hint_open_ios_settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .navigationTitle(L10n.string("hint_manage_permissions"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshStatus() }
        .onAppear {
            Task { await refreshStatus() }
        }
    }

    private func refreshStatus() async {
        let status = await ExpenseReminderScheduler.notificationStatus()
        statusText = (status == .authorized || status == .provisional)
            ? L10n.string("hint_notifications_enabled")
            : L10n.string("hint_notifications_disabled")
    }
}
