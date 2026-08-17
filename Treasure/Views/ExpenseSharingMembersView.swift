import SwiftUI

struct ExpenseSharingMembersView: View {
    let groupId: String
    let isAdmin: Bool
    let isClosed: Bool

    @State private var members: [SharingMember] = []
    @State private var showingAdd = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage).foregroundColor(.red).font(.footnote)
            }
            if members.isEmpty {
                Text("No members yet.")
                    .foregroundColor(.secondary)
            }
            ForEach(members) { member in
                HStack(spacing: 12) {
                    Text(avatarLetter(member.displayName))
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.accentColor.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.displayName)
                            .font(.headline)
                        if shouldShowMobile(member) {
                            Text(member.mobile)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Text(member.isAdmin ? "Admin" : "Member")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(member.isAdmin ? Color.accentColor.opacity(0.12) : Color(.systemGray6))
                        .foregroundColor(member.isAdmin ? .accentColor : .secondary)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 4)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if isAdmin && !member.isAdmin && !isClosed {
                        Button(role: .destructive) {
                            Task { await remove(member) }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Group members")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if isAdmin && !isClosed {
                Button {
                    showingAdd = true
                } label: {
                    Label("Add member", systemImage: "plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddSharingMemberSheet(groupId: groupId) {
                showingAdd = false
                Task { await load() }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func avatarLetter(_ name: String) -> String {
        String(name.trimmingCharacters(in: .whitespaces).first ?? "?").uppercased()
    }

    private func shouldShowMobile(_ member: SharingMember) -> Bool {
        let digitsName = member.displayName.filter(\.isNumber)
        let digitsMobile = member.mobile.filter(\.isNumber)
        if digitsName.count >= 10 && digitsMobile.count >= 10 {
            return digitsName.suffix(10) != digitsMobile.suffix(10)
        }
        return !member.mobile.isEmpty && member.displayName != member.mobile
    }

    private func load() async {
        do {
            members = try await SharingApi.listMembers(groupId: groupId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func remove(_ member: SharingMember) async {
        do {
            try await SharingApi.removeMember(groupId: groupId, memberId: member.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct AddSharingMemberSheet: View {
    let groupId: String
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var mobile = ""
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Full name", text: $name)
                TextField("Mobile number", text: $mobile)
                    .keyboardType(.phonePad)
                Text("Use the same country code and number they use in Treasure.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                if let error {
                    Text(error).foregroundColor(.red).font(.footnote)
                }
            }
            .navigationTitle("Add member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { Task { await save() } }
                        .disabled(name.isEmpty || mobile.isEmpty || saving)
                }
            }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        do {
            try await SharingApi.addMember(groupId: groupId, name: name, mobile: mobile)
            onSaved()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
