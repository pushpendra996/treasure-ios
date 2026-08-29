import SwiftUI

struct ExpenseSharingView: View {
    @State private var groups: [SharingGroup] = []
    @State private var errorMessage: String?
    @State private var showingCreate = false

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            if groups.isEmpty {
                Text(L10n.string("hint_no_expense_groups"))
                    .foregroundColor(.secondary)
            }
            ForEach(groups) { g in
                NavigationLink(destination: ExpenseSharingGroupDetailView(groupId: g.id, title: g.name)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(g.name)
                            .font(.headline)
                        HStack(spacing: 8) {
                            Text(g.admin ? L10n.string("hint_role_admin") : L10n.string("hint_member_role"))
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(g.admin ? Color.accentColor.opacity(0.12) : Color(.systemGray5))
                                .foregroundColor(g.admin ? .accentColor : .secondary)
                                .clipShape(Capsule())
                            if g.closed {
                                Text("Closed")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(L10n.string("hint_expense_sharing"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateSharingGroupSheet {
                showingCreate = false
                Task { await load() }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
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

private struct CreateSharingGroupSheet: View {
    var onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Group name", text: $name)
                TextField("Description (optional)", text: $description)
                if let error {
                    Text(error).foregroundColor(.red).font(.footnote)
                }
            }
            .navigationTitle("Create group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await create() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || saving)
                }
            }
        }
    }

    private func create() async {
        saving = true
        defer { saving = false }
        do {
            try await SharingApi.createGroup(
                name: name.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespaces)
            )
            onCreated()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
