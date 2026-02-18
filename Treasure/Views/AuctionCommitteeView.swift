import SwiftUI

/// Lists committees the current user is a member of (fetched via backend API with Firebase ID token).
struct AuctionCommitteeView: View {
    @StateObject private var viewModel = AuctionCommitteeViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let message = viewModel.errorMessage {
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                }
            } else if viewModel.isEmpty {
                ContentUnavailableView {
                    Label("No Committees", systemImage: "person.3")
                } description: {
                    Text("You are not added to any committee yet.")
                }
            } else {
                List(viewModel.committees) { committee in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(committee.name)
                            .font(.headline)
                        Text(committee.typeDisplay)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Auction Committee")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadCommittees()
        }
        .refreshable {
            await viewModel.loadCommittees()
        }
    }
}

struct AuctionCommitteeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AuctionCommitteeView()
        }
    }
}
