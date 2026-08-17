import Foundation

struct SharingGroup: Identifiable, Decodable {
    let id: String
    let name: String
    let description: String?
    let adminUid: String
    let isAdmin: Bool?
    let isClosed: Bool?

    var admin: Bool { isAdmin == true }
    var closed: Bool { isClosed == true }
}

struct SharingGroupsResponse: Decodable {
    let success: Bool
    let data: [SharingGroup]
}

struct SharingGroupResponse: Decodable {
    let success: Bool
    let data: SharingGroup
}

struct SharingMember: Identifiable, Decodable {
    let id: String
    let userId: String?
    let mobile: String
    let name: String
    let role: String

    var isAdmin: Bool { role.lowercased() == "admin" }
    var displayName: String {
        if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return name }
        if !mobile.isEmpty { return mobile }
        return userId ?? "Member"
    }
}

struct SharingMembersResponse: Decodable {
    let success: Bool
    let data: [SharingMember]
}

struct SharingExpense: Identifiable, Decodable {
    let id: String
    let amount: Double
    let category: String
    let place: String
    let note: String
    let spentAt: String?
    let createdByUid: String
    let status: String
    let rejectionReason: String?
}

struct SharingExpensesResponse: Decodable {
    let success: Bool
    let data: [SharingExpense]
}

struct SharingReportData: Decodable {
    let totalApproved: Double
    let pendingTotal: Double
    let rejectedCount: Int
}

struct SharingReportResponse: Decodable {
    let success: Bool
    let data: SharingReportData
}

struct SharingSuccessResponse: Decodable {
    let success: Bool
    let message: String?
}

struct SharingAdminStatsResponse: Decodable {
    let success: Bool
    let data: SharingAdminStats
}

struct SharingAdminStats: Decodable {
    let groupCount: Int
}
