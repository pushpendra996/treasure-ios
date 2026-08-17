import FirebaseFirestore

extension Query {
    func getDocumentsAvailable() async throws -> QuerySnapshot {
        do {
            return try await getDocuments(source: .cache)
        } catch {
            return try await getDocuments()
        }
    }

    func getDocumentsCacheThenServer() async -> QuerySnapshot? {
        if let cache = try? await getDocuments(source: .cache) {
            return cache
        }
        return try? await getDocuments()
    }
}

extension DocumentReference {
    func getDocumentAvailable() async throws -> DocumentSnapshot {
        do {
            return try await getDocument(source: .cache)
        } catch {
            return try await getDocument()
        }
    }
}

func isOfflineError(_ error: Error) -> Bool {
    let ns = error as NSError
    if ns.domain == NSURLErrorDomain { return true }
    let domain = ns.domain.lowercased()
    if domain.contains("firestore") {
        return ns.code == 14 || ns.code == 4
    }
    let text = error.localizedDescription.lowercased()
    return text.contains("offline") || text.contains("network") || text.contains("internet")
}
