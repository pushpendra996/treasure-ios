import Foundation
import FirebaseAuth

/// Fetches committees for the current user via backend API using Firebase ID token (same secure flow as Android).
enum CommitteeApi {
    /// Production API (same base as Android `BuildConfig.API_BASE_URL`). No trailing slash (paths append with "/…").
    /// For local Node: `http://localhost:8000/api` or simulator `http://127.0.0.1:8000/api`.
    static let baseURL = "https://treasuremoney.in/api"
    
    static func fetchMemberCommittees() async throws -> [Committee] {
        guard let user = Auth.auth().currentUser else {
            return []
        }
        let token = try await user.getIDToken()
        let url = URL(string: "\(baseURL)/committee/member")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CommitteeApiError.invalidResponse }
        guard http.statusCode == 200 else {
            if let message = String(data: data, encoding: .utf8) {
                throw CommitteeApiError.serverError(statusCode: http.statusCode, message: message)
            }
            throw CommitteeApiError.serverError(statusCode: http.statusCode, message: nil)
        }
        
        let decoded = try JSONDecoder().decode(CommitteeMemberResponse.self, from: data)
        guard decoded.success else {
            throw CommitteeApiError.serverError(statusCode: 200, message: decoded.message)
        }
        return decoded.data
    }
}

enum CommitteeApiError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String?)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code, let msg):
            return msg ?? "Error \(code)"
        }
    }
}
