import Foundation

struct SharingGroup: Identifiable, Decodable {
    let id: String
    let name: String
    let description: String?
    let adminUid: String
    let isAdmin: Bool?
}

struct SharingGroupsResponse: Decodable {
    let success: Bool
    let data: [SharingGroup]
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

struct SharingAdminStatsResponse: Decodable {
    let success: Bool
    let data: SharingAdminStats
}

struct SharingAdminStats: Decodable {
    let groupCount: Int
}
