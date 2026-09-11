import SwiftUI
import UIKit
import FirebaseAuth

struct ExpenseSharingGroupDetailView: View {
    let groupId: String
    let title: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @State private var group: SharingGroup?
    @State private var report: SharingReportData?
    @State private var expenses: [SharingExpense] = []
    @State private var members: [SharingMember] = []
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
                    SharingExpenseRow(
                        expense: e,
                        spenderName: spenderName(e),
                        isAdmin: isAdmin,
                        isClosed: isClosed,
                        onApprove: { Task { await approve(e) } },
                        onReject: {
                            rejectTarget = e
                            showingReject = true
                        }
                    )
                    .environmentObject(categoryVM)
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
            AddSharingExpenseSheet(groupId: groupId, isAdmin: isAdmin) { expense in
                SharingGroupCache.applyLocalNewExpense(groupId, expense: expense)
                showingAddExpense = false
                if let cached = SharingGroupCache.peek(groupId) {
                    apply(cached)
                } else {
                    expenses.insert(expense, at: 0)
                }
                isLoading = false
            }
            .environmentObject(categoryVM)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .refreshable { await load(force: true) }
        .task { await load(force: SharingGroupCache.peek(groupId) == nil) }
        .onReceive(SharingDeepLinkStore.shared.$liveUpdateGroupId) { gid in
            guard gid == groupId else { return }
            Task { await load(force: true) }
        }
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

    private func spenderName(_ expense: SharingExpense) -> String {
        if let name = expense.createdByName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        if let member = members.first(where: { $0.userId == expense.createdByUid }) {
            return member.displayName
        }
        return L10n.string("hint_member_role")
    }

    private func load(force: Bool = true) async {
        if let cached = SharingGroupCache.peek(groupId) {
            apply(cached)
            isLoading = false
            if !force { return }
        } else {
            isLoading = true
        }
        defer { isLoading = false }
        do {
            let detail = try await SharingGroupCache.load(groupId, force: force)
            apply(detail)
        } catch {
            if SharingGroupCache.peek(groupId) == nil {
                group = nil
                report = nil
                members = []
                expenses = []
                errorMessage = error.localizedDescription
            }
        }
    }

    private func applyLocalCache() {
        if let cached = SharingGroupCache.peek(groupId) {
            apply(cached)
            isLoading = false
        }
    }

    private func apply(_ detail: SharingGroupDetailData) {
        group = detail.group
        report = detail.report
        members = detail.members
        if let rows = detail.expenses {
            expenses = rows
        }
        errorMessage = nil
    }

    private func closeGroup() async {
        do {
            try await SharingApi.closeGroup(groupId: groupId)
            SharingGroupCache.invalidate(groupId)
            await load(force: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteGroup() async {
        do {
            try await SharingApi.deleteGroup(groupId: groupId)
            SharingGroupCache.invalidate(groupId)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func approve(_ expense: SharingExpense) async {
        do {
            try await SharingApi.approveExpense(groupId: groupId, expenseId: expense.id)
            SharingGroupCache.applyLocalExpenseStatus(groupId, expenseId: expense.id, status: "approved")
            applyLocalCache()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reject(_ expense: SharingExpense, reason: String) async {
        do {
            try await SharingApi.rejectExpense(groupId: groupId, expenseId: expense.id, reason: reason)
            SharingGroupCache.applyLocalExpenseStatus(
                groupId,
                expenseId: expense.id,
                status: "rejected",
                reason: reason
            )
            rejectTarget = nil
            rejectReason = ""
            applyLocalCache()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SharingExpenseRow: View {
    let expense: SharingExpense
    let spenderName: String
    let isAdmin: Bool
    let isClosed: Bool
    var onApprove: () -> Void
    var onReject: () -> Void

    @EnvironmentObject private var categoryVM: CategoryViewModel
    @ObservedObject private var currencyStore = CurrencyStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                CategoryImageView(
                    imageUrl: categoryVM.getCategoryImage(for: expense.category),
                    size: 44,
                    name: expense.category
                )
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(expense.category.isEmpty ? "General" : expense.category)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(formattedAmount(expense.amount, fractionDigits: 2))
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    HStack(alignment: .center, spacing: 8) {
                        Text(String(format: L10n.string("hint_spent_by"), spenderName))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Text(statusLabel)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(statusColor.opacity(0.18))
                            .foregroundColor(statusColor)
                            .clipShape(Capsule())
                    }
                    let meta = [expense.place, expense.note].filter { !$0.isEmpty }.joined(separator: " · ")
                    if !meta.isEmpty {
                        Text(meta)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            if isAdmin && !isClosed && expense.status.lowercased() == "pending" {
                HStack {
                    Button(L10n.string("hint_approve"), action: onApprove)
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    Button(L10n.string("hint_reject"), action: onReject)
                        .buttonStyle(.bordered)
                        .tint(.red)
                }
            }
        }
        .padding(.vertical, 4)
        .id(currencyStore.code)
    }

    private var statusLabel: String {
        switch expense.status.lowercased() {
        case "approved": return L10n.string("hint_sharing_approved_short")
        case "rejected": return L10n.string("hint_sharing_rejected_short")
        default: return L10n.string("hint_sharing_pending_short")
        }
    }

    private var statusColor: Color {
        switch expense.status.lowercased() {
        case "approved": return .green
        case "rejected": return .red
        default: return Color.accentColor
        }
    }
}

private struct AddSharingExpenseSheet: View {
    let groupId: String
    var isAdmin: Bool = false
    var onSaved: (SharingExpense) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var categoryVM: CategoryViewModel
    @State private var amount = ""
    @State private var selectedCategory: Category?
    @State private var showingCategoryPicker = false
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
                Button {
                    showingCategoryPicker = true
                } label: {
                    HStack {
                        if let category = selectedCategory {
                            CategoryImageView(imageUrl: category.image, size: 24, name: category.name)
                            Text(category.name)
                                .foregroundColor(.primary)
                        } else {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(.accentColor)
                            Text(L10n.string("hint_select_category"))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }
                TextField("Where (optional)", text: $place)
                TextField("Note (optional)", text: $note)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                if let error {
                    Text(error).foregroundColor(.red).font(.footnote)
                }
            }
            .scrollDismissesKeyboard(.interactively)
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
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(selectedCategory: $selectedCategory, isExpense: true)
                    .environmentObject(categoryVM)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationContentInteraction(.scrolls)
            }
            .onAppear { applyDefaultCategoryIfNeeded() }
            .onChange(of: categoryVM.expenseCategories.count) { _, _ in
                applyDefaultCategoryIfNeeded()
            }
        }
    }

    private func applyDefaultCategoryIfNeeded() {
        guard selectedCategory == nil else { return }
        selectedCategory = categoryVM.expenseCategories.first
    }

    private func save() async {
        guard let value = Double(amount) else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        saving = true
        defer { saving = false }
        do {
            let expenseId = try await SharingApi.addExpense(
                groupId: groupId,
                amount: value,
                category: selectedCategory?.name ?? "General",
                place: place,
                note: note
            )
            let iso = ISO8601DateFormatter().string(from: Date())
            let name = Auth.auth().currentUser?.displayName
            let expense = SharingExpense(
                id: expenseId,
                amount: value,
                category: selectedCategory?.name ?? "General",
                place: place,
                note: note,
                spentAt: iso,
                createdByUid: Auth.auth().currentUser?.uid ?? "",
                createdByName: name,
                status: isAdmin ? "approved" : "pending",
                rejectionReason: nil
            )
            onSaved(expense)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
