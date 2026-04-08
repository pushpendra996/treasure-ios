import SwiftUI

/// Hub for shared expense groups (parity with Android footer entry).
struct ExpenseSharingView: View {
    @State private var groups: [SharingGroup] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            ForEach(groups) { g in
                NavigationLink(destination: ExpenseSharingGroupDetailView(groupId: g.id, title: g.name)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(g.name)
                            .font(.headline)
                        if g.isAdmin == true {
                            Text("Admin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Split expenses")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
    }

    private func load() async {
        errorMessage = nil
        do {
            groups = try await SharingApi.fetchMyGroups()
        } catch {
            errorMessage = error.localizedDescription
            groups = []
        }
    }
}
