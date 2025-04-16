import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.greeting)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(viewModel.personName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        if let phoneNumber = viewModel.personMobileNo {
                            Text(phoneNumber)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                    .onTapGesture {
                        viewModel.onTapProfile()
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        viewModel.signOut()
                        dismiss()
                    } label: {
                        Text("Sign Out")
                    }
                }
                
                if let appInfo = viewModel.appInfo {
                    Section {
                        Text(appInfo)
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.onAppear()
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
