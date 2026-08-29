import SwiftUI

struct ExpenseSharingGroupDetailView: View {
    let groupId: String
    let title: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @State private var group: SharingGroup?
    @State private var report: SharingReportData?
    @State private var expenses: [SharingExpense] = []
    @State private var isLoading = true
    @State private var showingAddExpense = false
    @State private var errorMessage: String?
    @State private var showingReject = false
    @State private var rejectTarget: SharingExpense?
    @State private var rejectReason = ""
    @ObservedObject private var currencyStore = CurrencyStore.shared

    private var isAdmin: Bool { group?.admin == true }
    private var isClosed: Bool { group?.closed == true }

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage).foregroundColor(.red).font(.footnote)
            }
            if let report {
                Section(L10n.string("hint_reports_summary")) {
                    LabeledContent(L10n.string("hint_sharing_approved_short"), value: formattedAmount(report.totalApproved, fractionDigits: 2))
                    LabeledContent(L10n.string("hint_sharing_pending_short"), value: formattedAmount(report.pendingTotal, fractionDigits: 2))
                    LabeledContent(L10n.string("hint_sharing_rejected_short"), value: "\(report.rejectedCount)")
                }
            }
            Section(L10n.string("hint_expenses")) {
                if expenses.isEmpty && !isLoading {
                    Text(L10n.string("hint_no_shared_expenses"))
                        .foregroundColor(.secondary)
                }
                ForEach(expenses) { e in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(formattedAmount(e.amount, fractionDigits: 2))
                                .font(.headline)
                            Spacer()
                            Text(statusLabel(e.status))
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(e.status).opacity(0.18))
                                .foregroundColor(statusColor(e.status))
                                .clipShape(Capsule())
                        }
                        Text([e.category, e.place, e.note].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if isAdmin && !isClosed && e.status.lowercased() == "pending" {
                            HStack {
                                Button(L10n.string("hint_approve")) {
                                    Task { await approve(e) }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                Button(L10n.string("hint_reject")) {
                                    rejectTarget = e
                                    showingReject = true
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            if isAdmin && !isClosed {
                Section {
                    Button(L10n.string("hint_close_group"), role: .destructive) {
                        Task { await closeGroup() }
                    }
                    Button(L10n.string("hint_delete_group"), role: .destructive) {
                        Task { await deleteGroup() }
                    }
                }
            }
        }
        .id(currencyStore.code)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ExpenseSharingMembersView(groupId: groupId, isAdmin: isAdmin, isClosed: isClosed)) {
                    Text(L10n.string("hint_members"))
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isAdmin && !isClosed {
                Button {
                    showingAddExpense = true
                } label: {
                    Label(L10n.string("hint_add_shared_expense"), systemImage: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingAddExpense) {
            AddSharingExpenseSheet(groupId: groupId) {
                showingAddExpense = false
                Task { await load() }
            }
            .environmentObject(categoryVM)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .refreshable { await load() }
        .task { await load() }
        .alert(L10n.string("hint_reject"), isPresented: $showingReject) {
            TextField(L10n.string("hint_rejection_reason"), text: $rejectReason)
            Button(L10n.string("hint_cancel"), role: .cancel) {
                rejectTarget = nil
                rejectReason = ""
            }
            Button(L10n.string("hint_reject"), role: .destructive) {
                if let rejectTarget {
                    Task { await reject(rejectTarget, reason: rejectReason) }
                }
            }
        }
    }

    private func statusLabel(_ status: String) -> String {
        switch status.lowercased() {
        case "approved": return L10n.string("hint_sharing_approved_short")
        case "rejected": return L10n.string("hint_sharing_rejected_short")
        default: return L10n.string("hint_sharing_pending_short")
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "approved": return .green
        case "rejected": return .red
        default: return .orange
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do { group = try await SharingApi.getGroup(groupId: groupId) } catch { group = nil }
        do { report = try await SharingApi.fetchReport(groupId: groupId) } catch { report = nil }
        do { expenses = try await SharingApi.listExpenses(groupId: groupId) } catch { expenses = [] }
    }

    private func closeGroup() async {
        do {
            try await SharingApi.closeGroup(groupId: groupId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteGroup() async {
        do {
            try await SharingApi.deleteGroup(groupId: groupId)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func approve(_ expense: SharingExpense) async {
        do {
            try await SharingApi.approveExpense(groupId: groupId, expenseId: expense.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reject(_ expense: SharingExpense, reason: String) async {
        do {
            try await SharingApi.rejectExpense(groupId: groupId, expenseId: expense.id, reason: reason)
            rejectTarget = nil
            rejectReason = ""
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AddSharingExpenseSheet: View {
    let groupId: String
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @State private var amount = ""
    @State private var category = "General"
    @State private var place = ""
    @State private var note = ""
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        NavigationView {
            Form {
                HStack {
                    Text(CurrencyStore.shared.symbol)
                        .foregroundColor(.secondary)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                Picker("Category", selection: $category) {
                    ForEach(categoryVM.expenseCategories) { item in
                        Text(item.name).tag(item.name)
                    }
                    Text("General").tag("General")
                }
                TextField("Where (optional)", text: $place)
                TextField("Note (optional)", text: $note)
                if let error {
                    Text(error).foregroundColor(.red).font(.footnote)
                }
            }
            .navigationTitle("Add expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(Double(amount) == nil || saving)
                }
            }
            .onAppear {
                if let first = categoryVM.expenseCategories.first {
                    category = first.name
                }
            }
        }
    }

    private func save() async {
        guard let value = Double(amount) else { return }
        saving = true
        defer { saving = false }
        do {
            try await SharingApi.addExpense(
                groupId: groupId,
                amount: value,
                category: category,
                place: place,
                note: note
            )
            onSaved()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
