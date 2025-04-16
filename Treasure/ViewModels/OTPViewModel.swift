import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
class OTPViewModel: ObservableObject {
    @Published var otpText = ""
    @Published var error: String?
    @Published var isLoading = false
    @Published var isVerified = false
    
    let verificationData: VerificationData
    
    init(verificationData: VerificationData) {
        self.verificationData = verificationData
    }
    
    func verifyOTP() async {
        guard !otpText.isEmpty, otpText.count == 6 else {
            error = "Please enter a valid OTP"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let credential = PhoneAuthProvider.provider().credential(
                withVerificationID: verificationData.verificationID,
                verificationCode: otpText
            )
            
            try await Auth.auth().signIn(with: credential)
            isVerified = true
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}

extension Notification.Name {
    static let authenticationSuccessful = Notification.Name("authenticationSuccessful")
    static let openUserDetails = Notification.Name("openUserDetails")
} 