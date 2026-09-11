import Foundation
import Combine

final class SharingDeepLinkStore: ObservableObject {
    static let shared = SharingDeepLinkStore()

    @Published var pendingGroupId: String?

    private init() {}

    func capture(_ userInfo: [AnyHashable: Any]) {
        let type = (userInfo["type"] as? String) ?? ""
        guard type == "sharing_new_expense" || type.hasPrefix("sharing_") else { return }
        guard let groupId = userInfo["groupId"] as? String, !groupId.isEmpty else { return }
        DispatchQueue.main.async {
            self.pendingGroupId = groupId
        }
    }

    func consume() -> String? {
        let id = pendingGroupId
        pendingGroupId = nil
        return id
    }
}
