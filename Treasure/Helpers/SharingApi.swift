import Foundation
import FirebaseAuth

/// Expense-sharing groups API (Firebase ID token), same base as `CommitteeApi`.
enum SharingApi {
    static let baseURL = CommitteeApi.baseURL

    static func fetchMyGroups() async throws -> [SharingGroup] {
        guard let user = Auth.auth().currentUser else { return [] }
        let token = try await user.getIDToken()
        let url = URL(string: "\(baseURL)/sharing/mobile/member")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CommitteeApiError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: String(data: data, encoding: .utf8))
        }
        let decoded = try JSONDecoder().decode(SharingGroupsResponse.self, from: data)
        guard decoded.success else { return [] }
        return decoded.data
    }

    static func listExpenses(groupId: String) async throws -> [SharingExpense] {
        guard let user = Auth.auth().currentUser else { return [] }
        let token = try await user.getIDToken()
        let url = URL(string: "\(baseURL)/sharing/mobile/\(groupId)/expenses")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CommitteeApiError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }
        let decoded = try JSONDecoder().decode(SharingExpensesResponse.self, from: data)
        guard decoded.success else { return [] }
        return decoded.data
    }

    static func fetchReport(groupId: String) async throws -> SharingReportData {
        guard let user = Auth.auth().currentUser else {
            throw CommitteeApiError.serverError(statusCode: 401, message: nil)
        }
        let token = try await user.getIDToken()
        let url = URL(string: "\(baseURL)/sharing/mobile/\(groupId)/reports")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CommitteeApiError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }
        let decoded = try JSONDecoder().decode(SharingReportResponse.self, from: data)
        guard decoded.success else {
            throw CommitteeApiError.serverError(statusCode: 200, message: "Report failed")
        }
        return decoded.data
    }
}
