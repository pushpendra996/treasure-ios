import Foundation
import Combine

final class SharingDeepLinkStore: ObservableObject {
    static let shared = SharingDeepLinkStore()

    @Published var pendingGroupId: String?
    @Published var liveUpdateGroupId: String?

    private init() {}

    func capture(_ userInfo: [AnyHashable: Any]) {
        guard let groupId = sharingGroupId(from: userInfo) else { return }
        DispatchQueue.main.async {
            self.pendingGroupId = groupId
            self.liveUpdateGroupId = groupId
        }
    }

    /// Foreground push: refresh open screens without navigating away.
    func notifyLiveUpdate(_ userInfo: [AnyHashable: Any]) {
        guard let groupId = sharingGroupId(from: userInfo) else { return }
        DispatchQueue.main.async {
            self.liveUpdateGroupId = groupId
        }
    }

    func consume() -> String? {
        let id = pendingGroupId
        pendingGroupId = nil
        return id
    }

    private func sharingGroupId(from userInfo: [AnyHashable: Any]) -> String? {
        let type = (userInfo["type"] as? String) ?? ""
        guard type == "sharing_new_expense" || type.hasPrefix("sharing_") else { return nil }
        let groupId = userInfo["groupId"] as? String
        return groupId?.isEmpty == false ? groupId : nil
    }
}
