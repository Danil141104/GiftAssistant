import Foundation
import Combine
import FirebaseFirestore

@MainActor
class RecipientViewModel: ObservableObject {
    @Published var recipients: [Recipient] = []
    @Published var isLoading = false
    @Published var showContactsPicker = false
    
    private let firebase = FirebaseService()
    private var listener: ListenerRegistration?
    
    // MARK: - Firestore
    
    func startListening(userID: String) {
        listener = firebase.listenToCollection(
            collection: "recipients",
            whereField: "userID",
            isEqualTo: userID
        ) { [weak self] (items: [Recipient]) in
            self?.recipients = items
        }
    }
    
    func addRecipient(_ recipient: Recipient) {
        Task {
            try? await firebase.addDocument(collection: "recipients", data: recipient, documentID: recipient.id)
        }
    }
    
    func deleteRecipient(_ recipient: Recipient) {
        Task {
            try? await firebase.deleteDocument(collection: "recipients", documentID: recipient.id)
        }
    }
    
    func stopListening() {
        listener?.remove()
    }
    
    // MARK: - Import from Contacts
    
    func importFromContact(_ candidate: ContactCandidate, userID: String, relationship: String, gender: String, contactsService: ContactsService) {
        let recipient = contactsService.makeRecipient(
            from: candidate,
            userID: userID,
            relationship: relationship,
            gender: gender
        )
        addRecipient(recipient)
    }
}
