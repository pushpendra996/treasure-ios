import SwiftUI
import FirebaseAuth

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var greeting = ""
    @Published var personName = "Guest"
    @Published var personMobileNo: String?
    @Published var appInfo: String?
    
    func onAppear() {
        // Set greeting based on time of day
        let hour = Calendar.current.component(.hour, from: Date())
        greeting = switch hour {
        case 0..<12: "Good Morning"
        case 12..<17: "Good Afternoon"
        default: "Good Evening"
        }
        
        // Get user data from UserDefaults
        if let userData = UserDefaults.standard.dictionary(forKey: "userData") {
            personName = userData["name"] as? String ?? "Guest"
            personMobileNo = Auth.auth().currentUser?.phoneNumber
        }
        
        // Get app version info
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            appInfo = "Version - \(version) ■ \(build)"
        }
    }
    
    func onTapProfile() {
        NotificationCenter.default.post(name: .openUserDetails, object: nil)
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
} 