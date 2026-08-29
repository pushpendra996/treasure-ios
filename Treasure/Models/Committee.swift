import Foundation

struct Committee: Identifiable, Decodable {
    let id: String
    let name: String
    let type: String
    let description: String?
    var isCreator: Bool?

    var typeDisplay: String {
        type.lowercased() == "auction"
            ? L10n.string("hint_auction_committee")
            : type.prefix(1).uppercased() + type.dropFirst()
    }
}

struct CommitteeMember: Identifiable, Decodable {
    let id: String
    let name: String
    let mobile: String
    let email: String?
    let address: String?
}

struct CommitteeMemberResponse: Decodable {
    let success: Bool
    let data: [Committee]
    let message: String?
}
