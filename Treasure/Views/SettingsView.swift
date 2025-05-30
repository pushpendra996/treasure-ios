import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            List {
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
            .navigationTitle("Settings")
            .onAppear {
                viewModel.onAppear()
            }
        }
    }
} 
