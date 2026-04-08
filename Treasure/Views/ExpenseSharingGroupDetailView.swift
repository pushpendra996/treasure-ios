import SwiftUI

/// Group detail: summary + expenses (approve or reject flows can be added in a follow-up).
struct ExpenseSharingGroupDetailView: View {
    let groupId: String
    let title: String

    @State private var report: SharingReportData?
    @State private var expenses: [SharingExpense] = []
    @State private var isLoading = true

    var body: some View {
        List {
            if let report {
                Section("Summary") {
                    Text(String(format: "Approved: %.2f", report.totalApproved))
                    Text(String(format: "Pending: %.2f", report.pendingTotal))
                    Text("Rejected entries: \(report.rejectedCount)")
                }
            }
            Section("Expenses") {
                if expenses.isEmpty && !isLoading {
                    Text("No expenses yet.")
                        .foregroundColor(.secondary)
                }
                ForEach(expenses) { e in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(String(format: "%.2f", e.amount))
                                .font(.headline)
                            Spacer()
                            Text(e.status.uppercased())
                                .font(.caption2)
                                .padding(4)
                                .background(statusColor(e.status).opacity(0.2))
                                .cornerRadius(4)
                        }
                        Text("\(e.category) · \(e.place)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if e.status == "rejected", let r = e.rejectionReason, !r.isEmpty {
                            Text(r)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
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
        do {
            report = try await SharingApi.fetchReport(groupId: groupId)
        } catch {
            report = nil
        }
        do {
            expenses = try await SharingApi.listExpenses(groupId: groupId)
        } catch {
            expenses = []
        }
    }
}
