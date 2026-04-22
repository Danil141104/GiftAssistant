import Foundation
import FirebaseFirestore

class FirebaseService {
    private let db = Firestore.firestore()
    
    // MARK: - Generic CRUD
    
    func fetchCollection<T: Codable>(collection: String, whereField: String? = nil, isEqualTo value: Any? = nil) async throws -> [T] {
        var query: Query = db.collection(collection)
        
        if let field = whereField, let val = value {
            query = query.whereField(field, isEqualTo: val)
        }
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: T.self)
        }
    }
    
    func addDocument<T: Codable>(collection: String, data: T, documentID: String? = nil) async throws {
        if let id = documentID {
            try db.collection(collection).document(id).setData(from: data)
        } else {
            _ = try db.collection(collection).addDocument(from: data)
        }
    }
    
    func updateDocument(collection: String, documentID: String, fields: [String: Any]) async throws {
        try await db.collection(collection).document(documentID).updateData(fields)
    }
    
    func deleteDocument(collection: String, documentID: String) async throws {
        try await db.collection(collection).document(documentID).delete()
    }
    
    // MARK: - Real-time Listener
    
    func listenToDocument<T: Codable>(collection: String, documentID: String, completion: @escaping (T?) -> Void) -> ListenerRegistration {
        return db.collection(collection).document(documentID).addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            let data = try? snapshot.data(as: T.self)
            completion(data)
        }
    }
    
    func listenToCollection<T: Codable>(collection: String, whereField: String? = nil, isEqualTo value: Any? = nil, completion: @escaping ([T]) -> Void) -> ListenerRegistration {
        var query: Query = db.collection(collection)
        
        if let field = whereField, let val = value {
            query = query.whereField(field, isEqualTo: val)
        }
        
        return query.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot else {
                completion([])
                return
            }
            let items = snapshot.documents.compactMap { doc in
                try? doc.data(as: T.self)
            }
            completion(items)
        }
    }
}
