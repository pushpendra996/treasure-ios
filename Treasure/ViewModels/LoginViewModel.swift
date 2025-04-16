import SwiftUI
import FirebaseAuth

struct VerificationData: Identifiable {
    let id = UUID()
    let verificationID: String
}

@MainActor
class LoginViewModel: ObservableObject {
    @Published var countryCode = "91"
    @Published var phoneNumber = ""
    @Published var error: String?
    @Published var isLoading = false
    @Published var verificationData: VerificationData?
    
    private let auth = Auth.auth()
    private let provider = PhoneAuthProvider.provider()
    
    func sendVerificationCode() async {
        guard !phoneNumber.isEmpty, phoneNumber.count >= 10 else {
            error = "Please enter a valid mobile number"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let formattedNumber = "+\(countryCode)\(phoneNumber)"
            let verificationID = try await provider.verifyPhoneNumber(
                formattedNumber,
                uiDelegate: PhoneAuthDelegateManager.shared.delegate
            )
            
            verificationData = VerificationData(verificationID: verificationID)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
} 
