import SwiftUI
import FirebaseFirestore

struct Country: Identifiable {
    let id: String
    let name: String
    let code: String
    let image: String
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.code = data["code"] as? String ?? ""
        self.image = data["image"] as? String ?? ""
    }
}

@MainActor
class CountryPickerViewModel: ObservableObject {
    @Published var countries: [Country] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let db = Firestore.firestore()
    
    func fetchCountries() async {
        isLoading = true
        error = nil
        
        do {
            let snapshot = try await db.collection("country").getDocuments()
            countries = snapshot.documents.map { doc in
                Country(id: doc.documentID, data: doc.data())
            }.sorted { $0.name < $1.name }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
} 