import Foundation
import FirebaseStorage

class StorageManager {
    static let shared = StorageManager()
    private let storage = Storage.storage()
    
    private init() {}
    
    func getImageURL(path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }
} 