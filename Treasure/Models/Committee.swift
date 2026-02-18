import Foundation

struct Committee: Identifiable, Decodable {
    let id: String
    let name: String
    let type: String
    let description: String?
    
    var typeDisplay: String {
        type.lowercased() == "auction" ? "Auction" : type.prefix(1).uppercased() + type.dropFirst()
    }
}

struct CommitteeMemberResponse: Decodable {
    let success: Bool
    let data: [Committee]
    let message: String?
}
