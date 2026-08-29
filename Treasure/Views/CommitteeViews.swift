import SwiftUI

struct CommitteeView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: AuctionCommitteeView()) {
                    Label(L10n.string("hint_auction_committee"), systemImage: "person.3.fill")
                }
                NavigationLink(destination: ManageCommitteesView()) {
                    Label(L10n.string("hint_manage_my_committees_short"), systemImage: "plus.rectangle.on.folder")
                }
            } header: {
                Text(L10n.string("hint_committee"))
            } footer: {
                Text(L10n.string("hint_manage_committees_desc"))
            }
        }
        .navigationTitle(L10n.string("hint_committee"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AuctionCommitteeView: View {
    @StateObject private var viewModel = AuctionCommitteeViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView(L10n.string("hint_loading"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage {
                ContentUnavailableView {
                    Label(L10n.string("hint_unable_to_load"), systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                }
            } else if viewModel.isEmpty {
                ContentUnavailableView {
                    Label(L10n.string("hint_no_committees_title"), systemImage: "person.3")
                } description: {
                    Text(L10n.string("hint_no_committees"))
                }
            } else {
                List(viewModel.committees) { committee in
                    NavigationLink(destination: CommitteeDetailView(committeeId: committee.id, title: committee.name)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(committee.name).font(.headline)
                            Text(committee.typeDisplay)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(L10n.string("hint_title_auction_committee"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadCommittees() }
        .refreshable { await viewModel.loadCommittees() }
    }
}

struct ManageCommitteesView: View {
    @State private var committees: [Committee] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingCreate = false

    var body: some View {
        Group {
            if isLoading && committees.isEmpty {
                ProgressView(L10n.string("hint_loading"))
            } else if committees.isEmpty {
                ContentUnavailableView {
                    Label(L10n.string("hint_no_committees_title"), systemImage: "plus.rectangle")
                } description: {
                    Text(L10n.string("hint_no_committees_created"))
                }
            } else {
                List(committees) { committee in
                    NavigationLink(destination: CommitteeDetailView(committeeId: committee.id, title: committee.name)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(committee.name).font(.headline)
                            if let description = committee.description, !description.isEmpty {
                                Text(description).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.string("hint_my_committees"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingCreate) {
            CreateCommitteeView {
                showingCreate = false
                Task { await load() }
            }
        }
        .task { await load() }
        .refreshable { await load() }
        .overlay {
            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundColor(.red).padding()
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            committees = try await CommitteeApi.fetchCreatedCommittees()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct CreateCommitteeView: View {
    var onCreated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var count = 0
    @State private var error: String?
    @State private var saving = false
    private let freeLimit = 2

    var body: some View {
        NavigationView {
            Form {
                TextField(L10n.string("hint_committee_name"), text: $name)
                TextField(L10n.string("hint_committee_description"), text: $description)
                Text(L10n.string("hint_committee_type_auction"))
                    .foregroundColor(.secondary)
                if count >= freeLimit {
                    Text(L10n.string("hint_committee_limit_reached"))
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                if let error {
                    Text(error).foregroundColor(.red).font(.footnote)
                }
            }
            .navigationTitle(L10n.string("hint_create_committee"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("hint_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("hint_save")) { Task { await save() } }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || saving || count >= freeLimit)
                }
            }
            .task {
                count = (try? await CommitteeApi.fetchCreatedCount()) ?? 0
            }
        }
    }

    private func save() async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            error = L10n.string("hint_enter_committee_name")
            return
        }
        saving = true
        defer { saving = false }
        do {
            _ = try await CommitteeApi.createCommittee(
                name: trimmed,
                description: description.trimmingCharacters(in: .whitespaces)
            )
            onCreated()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct CommitteeDetailView: View {
    let committeeId: String
    let title: String
    @State private var committee: Committee?
    @State private var members: [CommitteeMember] = []
    @State private var showingAdd = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let committee {
                Section(L10n.string("hint_committee_detail")) {
                    Text(committee.name).font(.headline)
                    if let description = committee.description, !description.isEmpty {
                        Text(description)
                    }
                    Text(committee.typeDisplay).foregroundColor(.secondary)
                }
            }
            Section(L10n.string("hint_members")) {
                if members.isEmpty {
                    Text(L10n.string("hint_no_members_yet")).foregroundColor(.secondary)
                }
                ForEach(members) { member in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name).font(.headline)
                        Text(member.mobile).font(.subheadline).foregroundColor(.secondary)
                        if let email = member.email, !email.isEmpty {
                            Text(email).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "person.badge.plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddCommitteeMemberSheet(committeeId: committeeId) {
                showingAdd = false
                Task { await load() }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        do { committee = try await CommitteeApi.fetchDetail(committeeId: committeeId) } catch { errorMessage = error.localizedDescription }
        do { members = try await CommitteeApi.fetchMembers(committeeId: committeeId) } catch { members = [] }
    }
}

private struct AddCommitteeMemberSheet: View {
    let committeeId: String
    var onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var mobile = ""
    @State private var email = ""
    @State private var address = ""
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        NavigationView {
            Form {
                TextField(L10n.string("hint_member_name"), text: $name)
                TextField(L10n.string("hint_member_mobile"), text: $mobile)
                    .keyboardType(.phonePad)
                TextField(L10n.string("hint_member_email"), text: $email)
                    .keyboardType(.emailAddress)
                TextField(L10n.string("hint_member_address"), text: $address)
                if let error {
                    Text(error).foregroundColor(.red).font(.footnote)
                }
            }
            .navigationTitle(L10n.string("hint_add_member"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("hint_cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("hint_add_member")) { Task { await save() } }
                        .disabled(name.isEmpty || mobile.isEmpty || saving)
                }
            }
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        do {
            try await CommitteeApi.addMember(
                committeeId: committeeId,
                name: name,
                mobile: mobile,
                email: email,
                address: address
            )
            onSaved()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
