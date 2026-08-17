import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var currencyStore = CurrencyStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingCurrency = false
    
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
                    Button {
                        showingCurrency = true
                    } label: {
                        HStack {
                            Label("Currency", systemImage: "dollarsign.circle")
                            Spacer()
                            Text(currencyStore.label)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
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
            .sheet(isPresented: $showingCurrency) {
                NavigationView {
                    CurrencyPickerView()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
