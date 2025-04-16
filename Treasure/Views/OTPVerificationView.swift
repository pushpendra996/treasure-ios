import SwiftUI
import FirebaseAuth

struct OTPVerificationView: View {
    @StateObject private var viewModel: OTPViewModel
    @Environment(\.dismiss) private var dismiss
    
    let phoneNumber: String
    
    init(verificationData: VerificationData, phoneNumber: String) {
        self.phoneNumber = phoneNumber
        _viewModel = StateObject(wrappedValue: OTPViewModel(verificationData: verificationData))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Verify OTP")
                .font(.title2)
                .padding(.top, 40)
            
            Text("OTP has been sent to")
                .foregroundColor(.gray)
            
            Text(phoneNumber)
                .font(.title3)
                .fontWeight(.semibold)
            
            // OTP Input Field
            TextField("Enter OTP", text: $viewModel.otpText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title2)
                .padding()
                .frame(maxWidth: 200)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 20)
            
            if let error = viewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal)
            }
            
            Button(action: {
                Task {
                    await viewModel.verifyOTP()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Verify")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal)
            .disabled(viewModel.otpText.count != 6 || viewModel.isLoading)
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onChange(of: viewModel.isVerified) { _, isVerified in
            if isVerified {
                NotificationCenter.default.post(name: .authenticationSuccessful, object: nil)
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationView {
        OTPVerificationView(
            verificationData: VerificationData(verificationID: "preview"),
            phoneNumber: "+91 1234567890"
        )
    }
} 