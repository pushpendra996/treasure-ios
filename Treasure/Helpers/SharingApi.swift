import Foundation
import FirebaseAuth

enum SharingApi {
    static let baseURL = CommitteeApi.baseURL

    static func fetchMyGroups() async throws -> [SharingGroup] {
        let decoded: SharingGroupsResponse = try await get("/sharing/mobile/member")
        return decoded.success ? decoded.data : []
    }

    static func createGroup(name: String, description: String) async throws {
        try await post("/sharing/mobile", body: [
            "name": name,
            "description": description,
        ])
    }

    static func getGroup(groupId: String) async throws -> SharingGroup {
        let decoded: SharingGroupResponse = try await get("/sharing/mobile/\(groupId)")
        guard decoded.success else {
            throw CommitteeApiError.serverError(statusCode: 200, message: "Group not found")
        }
        return decoded.data
    }

    static func listMembers(groupId: String) async throws -> [SharingMember] {
        let decoded: SharingMembersResponse = try await get("/sharing/mobile/\(groupId)/members")
        return decoded.success ? decoded.data : []
    }

    static func addMember(groupId: String, name: String, mobile: String) async throws {
        try await post("/sharing/mobile/\(groupId)/members", body: [
            "name": name,
            "mobile": mobile,
        ])
    }

    static func removeMember(groupId: String, memberId: String) async throws {
        try await delete("/sharing/mobile/\(groupId)/members/\(memberId)")
    }

    static func listExpenses(groupId: String) async throws -> [SharingExpense] {
        let decoded: SharingExpensesResponse = try await get("/sharing/mobile/\(groupId)/expenses")
        return decoded.success ? decoded.data : []
    }

    static func addExpense(
        groupId: String,
        amount: Double,
        category: String,
        place: String,
        note: String
    ) async throws {
        try await post("/sharing/mobile/\(groupId)/expenses", body: [
            "amount": amount,
            "category": category,
            "place": place,
            "note": note,
        ])
    }

    static func deleteExpense(groupId: String, expenseId: String) async throws {
        try await delete("/sharing/mobile/\(groupId)/expenses/\(expenseId)")
    }

    static func fetchReport(groupId: String) async throws -> SharingReportData {
        let decoded: SharingReportResponse = try await get("/sharing/mobile/\(groupId)/reports")
        guard decoded.success else {
            throw CommitteeApiError.serverError(statusCode: 200, message: "Report failed")
        }
        return decoded.data
    }

    static func closeGroup(groupId: String) async throws {
        try await post("/sharing/mobile/\(groupId)/close", body: [:])
    }

    static func deleteGroup(groupId: String) async throws {
        try await delete("/sharing/mobile/\(groupId)")
    }

    private static func get<T: Decodable>(_ path: String) async throws -> T {
        let (data, _) = try await send(path, method: "GET", body: nil)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func post(_ path: String, body: [String: Any]) async throws {
        let payload = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await send(path, method: "POST", body: payload)
        let decoded = try JSONDecoder().decode(SharingSuccessResponse.self, from: data)
        guard decoded.success else {
            throw CommitteeApiError.serverError(statusCode: 200, message: decoded.message)
        }
    }

    private static func delete(_ path: String) async throws {
        let (data, http) = try await send(path, method: "DELETE", body: nil)
        if http.statusCode == 200 && data.isEmpty { return }
        let decoded = try JSONDecoder().decode(SharingSuccessResponse.self, from: data)
        guard decoded.success else {
            throw CommitteeApiError.serverError(statusCode: http.statusCode, message: decoded.message)
        }
    }

    private static func send(_ path: String, method: String, body: Data?) async throws -> (Data, HTTPURLResponse) {
        guard NetworkMonitor.shared.isConnected else { throw CommitteeApiError.needsInternet }
        guard let user = Auth.auth().currentUser else {
            throw CommitteeApiError.serverError(statusCode: 401, message: nil)
        }
        let token = try await user.getIDToken()
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw CommitteeApiError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CommitteeApiError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            throw CommitteeApiError.serverError(
                statusCode: http.statusCode,
                message: String(data: data, encoding: .utf8)
            )
        }
        return (data, http)
    }
}
