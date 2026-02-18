import SwiftUI

/// Committee hub: options like "Auction Committee" (matches Android Committee screen).
struct CommitteeView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(destination: AuctionCommitteeView()) {
                    Label("Auction Committee", systemImage: "person.3.fill")
                }
            } header: {
                Text("Committee")
            } footer: {
                Text("View committees you are a member of.")
            }
        }
        .navigationTitle("Committee")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CommitteeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CommitteeView()
        }
    }
}
