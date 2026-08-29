import Foundation
import FirebaseAuth

enum CommitteeApi {
    static let baseURL = "https://treasuremoney.in/api"

    static func fetchMemberCommittees() async throws -> [Committee] {
        try await getList("/committee/member")
    }

    static func fetchCreatedCommittees(type: String = "auction") async throws -> [Committee] {
        let list = try await getList("/committee/mobile/created?type=\(type)")
        return list.map {
            var copy = $0
            copy.isCreator = true
            return copy
        }
    }

    static func fetchCreatedCount(type: String = "auction") async throws -> Int {
        guard NetworkMonitor.shared.isConnected else { throw CommitteeApiError.needsInternet }
        let token = try await idToken()
        guard let url = URL(string: "\(baseURL)/committee/mobile/count?type=\(type)") else {
            throw CommitteeApiError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw CommitteeApiError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard json?["success"] as? Bool == true else {
            throw CommitteeApiError.serverError(statusCode: 200, message: json?["message"] as? String)
        }
        if let n = json?["data"] as? Int { return n }
        if let n = json?["data"] as? NSNumber { return n.intValue }
        return 0
    }

    static func createCommittee(name: String, type: String = "auction", description: String) async throws -> String {
        let payload = try JSONSerialization.data(withJSONObject: [
            "name": name,
            "type": type,
            "description": description,
        ])
        let data = try await send("/committee/mobile", method: "POST", body: payload)
        let decoded = try JSONDecoder().decode(CommitteeCreateResponse.self, from: data)
        guard decoded.success, let id = decoded.data, !id.isEmpty else {
            throw CommitteeApiError.serverError(statusCode: 200, message: decoded.message)
        }
        return id
    }

    static func fetchDetail(committeeId: String) async throws -> Committee {
        try await getItem("/committee/mobile/\(committeeId)")
    }

    static func fetchMembers(committeeId: String) async throws -> [CommitteeMember] {
        guard NetworkMonitor.shared.isConnected else { throw CommitteeApiError.needsInternet }
        let token = try await idToken()
        guard let url = URL(string: "\(baseURL)/committee/mobile/\(committeeId)/members") else {
            throw CommitteeApiError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        try throwIfNeeded(data, response)
        let decoded = try JSONDecoder().decode(CommitteeMembersResponse.self, from: data)
        guard decoded.success else {
            throw CommitteeApiError.serverError(statusCode: 200, message: decoded.message)
        }
        return decoded.data
    }

    static func addMember(
        committeeId: String,
        name: String,
        mobile: String,
        email: String,
        address: String
    ) async throws {
        let payload = try JSONSerialization.data(withJSONObject: [
            "name": name,
            "mobile": mobile,
            "email": email,
            "address": address,
        ])
        let data = try await send("/committee/mobile/\(committeeId)/members", method: "POST", body: payload)
        let decoded = try JSONDecoder().decode(SharingSuccessResponse.self, from: data)
        guard decoded.success else {
            throw CommitteeApiError.serverError(statusCode: 200, message: decoded.message)
        }
    }

    private static func getList(_ path: String) async throws -> [Committee] {
        let data = try await send(path, method: "GET", body: nil)
        let decoded = try JSONDecoder().decode(CommitteeMemberResponse.self, from: data)
        guard decoded.success else {
            throw CommitteeApiError.serverError(statusCode: 200, message: decoded.message)
        }
        return decoded.data
    }

    private static func getItem(_ path: String) async throws -> Committee {
        let data = try await send(path, method: "GET", body: nil)
        let decoded = try JSONDecoder().decode(CommitteeDetailResponse.self, from: data)
        guard decoded.success else {
            throw CommitteeApiError.serverError(statusCode: 200, message: decoded.message)
        }
        return decoded.data
    }

    private static func send(_ path: String, method: String, body: Data?) async throws -> Data {
        guard NetworkMonitor.shared.isConnected else { throw CommitteeApiError.needsInternet }
        let token = try await idToken()
        guard let url = URL(string: "\(baseURL)\(path)") else { throw CommitteeApiError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: request)
        try throwIfNeeded(data, response)
        return data
    }

    private static func throwIfNeeded(_ data: Data, _ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { throw CommitteeApiError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            throw CommitteeApiError.serverError(
                statusCode: http.statusCode,
                message: String(data: data, encoding: .utf8)
            )
        }
    }

    private static func idToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw CommitteeApiError.serverError(statusCode: 401, message: L10n.string("hint_please_log_in"))
        }
        return try await user.getIDToken()
    }
}

enum CommitteeApiError: LocalizedError {
    case invalidResponse
    case needsInternet
    case serverError(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return L10n.string("hint_failed")
        case .needsInternet:
            return L10n.string("hint_needs_internet")
        case .serverError(_, let msg):
            return msg ?? L10n.string("hint_failed")
        }
    }
}

struct CommitteeCreateResponse: Decodable {
    let success: Bool
    let data: String?
    let message: String?
}

struct CommitteeDetailResponse: Decodable {
    let success: Bool
    let data: Committee
    let message: String?
}

struct CommitteeMembersResponse: Decodable {
    let success: Bool
    let data: [CommitteeMember]
    let message: String?
}
