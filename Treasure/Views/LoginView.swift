import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showingCountryPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter your mobile number")
                .font(.title2)
                .padding(.top, 40)
            
            HStack {
                Button(action: {
                    showingCountryPicker = true
                }) {
                    HStack {
                        Text("+\(viewModel.countryCode)")
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                TextField("Mobile Number", text: $viewModel.phoneNumber)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal)
            }
            
            Button(action: {
                Task {
                    await viewModel.sendVerificationCode()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Continue")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .disabled(viewModel.phoneNumber.count < 10 || viewModel.isLoading)
            
            Text("We'll send you a verification code")
                .foregroundColor(.gray)
                .font(.subheadline)
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCountryPicker) {
            CountryPickerView(selectedCountryCode: $viewModel.countryCode)
        }
        .fullScreenCover(item: $viewModel.verificationData) { data in
            NavigationView {
                OTPVerificationView(
                    verificationData: data,
                    phoneNumber: "+\(viewModel.countryCode)\(viewModel.phoneNumber)"
                )
            }
        }
    }
}

struct CountryPickerView: View {
    @StateObject private var viewModel = CountryPickerViewModel()
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedCountryCode: String
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List(viewModel.countries) { country in
                        Button(action: {
                            selectedCountryCode = country.code
                            dismiss()
                        }) {
                            HStack {
                                if !country.image.isEmpty {
                                    AsyncImage(url: URL(string: country.image)) { image in
                                        image
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 30, height: 30)
                                    }
                                }
                                
                                Text(country.name)
                                Spacer()
                                Text("+\(country.code)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    if let error = viewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.fetchCountries()
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LoginView()
        }
    }
} 