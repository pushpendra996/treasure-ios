import Foundation
import SwiftUI

@MainActor
class AuctionCommitteeViewModel: ObservableObject {
    @Published var committees: [Committee] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEmpty = false
    
    func loadCommittees() async {
        isLoading = true
        errorMessage = nil
        isEmpty = false
        
        do {
            let list = try await CommitteeApi.fetchMemberCommittees()
            committees = list
            isEmpty = list.isEmpty
        } catch {
            errorMessage = error.localizedDescription
            committees = []
            isEmpty = true
        }
        isLoading = false
    }
}
