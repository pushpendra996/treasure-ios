import SwiftUI
import FirebaseAuth

struct UserDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UserDetailsViewModel()
    
    var body: some View {
        Form {
            Section {
                TextField("Full Name", text: $viewModel.name)
                    .textContentType(.name)
                    .autocapitalization(.words)
                
                TextField("Email (Optional)", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                if let phoneNumber = Auth.auth().currentUser?.phoneNumber {
                    HStack {
                        Text("Phone Number")
                        Spacer()
                        Text(phoneNumber)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section {
                Button {
                    Task {
                        await viewModel.saveUserDetails()
                    }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.name.isEmpty || viewModel.isLoading)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDetailsSaved)) { _ in
            dismiss()
        }
    }
}

extension Notification.Name {
    static let userDetailsSaved = Notification.Name("userDetailsSaved")
} 