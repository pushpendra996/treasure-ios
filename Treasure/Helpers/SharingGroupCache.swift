import Foundation

enum SharingGroupCache {
    private static let lock = NSLock()
    private static var store: [String: SharingGroupDetailData] = [:]

    static func peek(_ groupId: String) -> SharingGroupDetailData? {
        lock.lock()
        defer { lock.unlock() }
        return store[groupId]
    }

    static func put(_ groupId: String, _ data: SharingGroupDetailData) {
        lock.lock()
        store[groupId] = data
        lock.unlock()
    }

    static func invalidate(_ groupId: String) {
        lock.lock()
        store[groupId] = nil
        lock.unlock()
    }

    static func prefetch(_ groupId: String) {
        Task {
            _ = try? await load(groupId, force: false)
        }
    }

    static func load(_ groupId: String, force: Bool = false) async throws -> SharingGroupDetailData {
        if !force, let cached = peek(groupId) {
            return cached
        }
        return try await fetch(groupId)
    }

    static func applyLocalNewExpense(_ groupId: String, expense: SharingExpense) {
        guard let current = peek(groupId) else { return }
        var expenses = current.expenses ?? []
        expenses.removeAll { $0.id == expense.id }
        expenses.insert(expense, at: 0)
        put(groupId, current.replacing(expenses: expenses, report: current.report.adding(expense)))
    }

    static func applyLocalExpenseStatus(_ groupId: String, expenseId: String, status: String, reason: String? = nil) {
        guard let current = peek(groupId) else { return }
        var expenses = current.expenses ?? []
        guard let index = expenses.firstIndex(where: { $0.id == expenseId }) else { return }
        let old = expenses[index]
        let updated = SharingExpense(
            id: old.id,
            amount: old.amount,
            category: old.category,
            place: old.place,
            note: old.note,
            spentAt: old.spentAt,
            createdByUid: old.createdByUid,
            createdByName: old.createdByName,
            status: status,
            rejectionReason: reason
        )
        expenses[index] = updated
        let report = current.report.removing(old).adding(updated)
        put(groupId, current.replacing(expenses: expenses, report: report))
    }

    static func applyLocalExpenseRemoved(_ groupId: String, expenseId: String) {
        guard let current = peek(groupId) else { return }
        var expenses = current.expenses ?? []
        guard let old = expenses.first(where: { $0.id == expenseId }) else { return }
        expenses.removeAll { $0.id == expenseId }
        put(groupId, current.replacing(expenses: expenses, report: current.report.removing(old)))
    }

    private static func fetch(_ groupId: String) async throws -> SharingGroupDetailData {
        let detail = try await SharingApi.fetchDetail(groupId: groupId)
        put(groupId, detail)
        return detail
    }
}

extension SharingGroupDetailData {
    func replacing(expenses: [SharingExpense], report: SharingReportData) -> SharingGroupDetailData {
        SharingGroupDetailData(group: group, members: members, report: report, expenses: expenses)
    }
}

extension SharingReportData {
    func adding(_ expense: SharingExpense) -> SharingReportData {
        switch expense.status.lowercased() {
        case "approved":
            return SharingReportData(
                totalApproved: totalApproved + expense.amount,
                pendingTotal: pendingTotal,
                rejectedCount: rejectedCount
            )
        case "pending":
            return SharingReportData(
                totalApproved: totalApproved,
                pendingTotal: pendingTotal + expense.amount,
                rejectedCount: rejectedCount
            )
        case "rejected":
            return SharingReportData(
                totalApproved: totalApproved,
                pendingTotal: pendingTotal,
                rejectedCount: rejectedCount + 1
            )
        default:
            return self
        }
    }

    func removing(_ expense: SharingExpense) -> SharingReportData {
        switch expense.status.lowercased() {
        case "approved":
            return SharingReportData(
                totalApproved: max(0, totalApproved - expense.amount),
                pendingTotal: pendingTotal,
                rejectedCount: rejectedCount
            )
        case "pending":
            return SharingReportData(
                totalApproved: totalApproved,
                pendingTotal: max(0, pendingTotal - expense.amount),
                rejectedCount: rejectedCount
            )
        case "rejected":
            return SharingReportData(
                totalApproved: totalApproved,
                pendingTotal: pendingTotal,
                rejectedCount: max(0, rejectedCount - 1)
            )
        default:
            return self
        }
    }
}
