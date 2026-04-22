import Foundation
import Combine
import FirebaseFirestore

@MainActor
class GroupRoomViewModel: ObservableObject {
    @Published var rooms: [GroupRoom] = []
    @Published var currentRoom: GroupRoom?
    @Published var contributions: [Contribution] = []
    @Published var pollOptions: [PollOption] = []
    @Published var isLoading = false
    @Published var unreadCount: Int = 0

    private let firebase = FirebaseService()
    private var roomListener: ListenerRegistration?
    private var contributionListener: ListenerRegistration?
    private var pollListener: ListenerRegistration?
    private let db = Firestore.firestore()

    // MARK: - Listen to all rooms where user is a member

    func startListening(userID: String) {
        roomListener?.remove()
        roomListener = db.collection("groupRooms")
            .whereField("memberIDs", arrayContains: userID)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let docs = snap?.documents else { return }
                self.rooms = docs.compactMap { doc -> GroupRoom? in
                    try? doc.data(as: GroupRoom.self)
                }
                .sorted { $0.createdAt > $1.createdAt }
            }
    }

    // MARK: - Create room

    func createRoom(organizerID: String, recipientName: String, occasion: String, budgetGoal: Double) {
        let code = generateCode()
        let room = GroupRoom(
            organizerID: organizerID,
            recipientName: recipientName,
            occasion: occasion,
            budgetGoal: budgetGoal,
            memberIDs: [organizerID],
            inviteCode: code
        )
        Task {
            try? await db.collection("groupRooms").document(room.id).setData(from: room)
        }
    }

    func createRoomAndReturnCode(organizerID: String, recipientName: String, occasion: String, budgetGoal: Double) -> String {
        let code = generateCode()
        let room = GroupRoom(
            organizerID: organizerID,
            recipientName: recipientName,
            occasion: occasion,
            budgetGoal: budgetGoal,
            memberIDs: [organizerID],
            inviteCode: code
        )
        Task {
            try? await db.collection("groupRooms").document(room.id).setData(from: room)
        }
        return code
    }

    // MARK: - Join room

    func joinRoom(inviteCode: String, userID: String) async -> Bool {
        do {
            let snap = try await db.collection("groupRooms")
                .whereField("inviteCode", isEqualTo: inviteCode)
                .getDocuments()
            guard let doc = snap.documents.first,
                  var room = try? doc.data(as: GroupRoom.self) else { return false }

            if !room.memberIDs.contains(userID) {
                room.memberIDs.append(userID)
                try await db.collection("groupRooms").document(room.id)
                    .updateData(["memberIDs": room.memberIDs])
            }
            return true
        } catch {
            return false
        }
    }

    // MARK: - Contributions

    func addContribution(roomID: String, userID: String, userName: String, amount: Double) {
        let contribution = Contribution(roomID: roomID, userID: userID, userName: userName, amount: amount)
        Task {
            try? await firebase.addDocument(collection: "contributions", data: contribution)
            if let room = currentRoom {
                let newTotal = room.currentTotal + amount
                try? await db.collection("groupRooms").document(roomID)
                    .updateData(["currentTotal": newTotal])
            }
        }
    }

    // MARK: - Poll

    func addPollOption(roomID: String, option: String) {
        let poll = PollOption(roomID: roomID, name: option)
        Task {
            try? await firebase.addDocument(collection: "polls", data: poll, documentID: poll.id)
        }
    }

    func vote(roomID: String, optionID: String, userID: String) {
        guard let option = pollOptions.first(where: { $0.id == optionID }) else { return }
        var newVoterIDs = option.voterIDs
        var newVotes = option.votes
        if newVoterIDs.contains(userID) {
            newVoterIDs.removeAll { $0 == userID }
            newVotes = max(0, newVotes - 1)
        } else {
            newVoterIDs.append(userID)
            newVotes += 1
        }
        Task {
            try? await firebase.updateDocument(
                collection: "polls", documentID: optionID,
                fields: ["votes": newVotes, "voterIDs": newVoterIDs]
            )
        }
    }

    // MARK: - Room detail listeners

    func listenToRoom(roomID: String) {
        roomListener?.remove()
        roomListener = db.collection("groupRooms")
            .document(roomID)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let snap else { return }
                self.currentRoom = try? snap.data(as: GroupRoom.self)
            }

        contributionListener = firebase.listenToCollection(
            collection: "contributions",
            whereField: "roomID",
            isEqualTo: roomID
        ) { [weak self] (items: [Contribution]) in
            self?.contributions = items.sorted { $0.createdAt > $1.createdAt }
        }

        pollListener = firebase.listenToCollection(
            collection: "polls",
            whereField: "roomID",
            isEqualTo: roomID
        ) { [weak self] (items: [PollOption]) in
            self?.pollOptions = items.sorted { $0.votes > $1.votes }
        }
    }

    func stopListening() {
        roomListener?.remove()
        contributionListener?.remove()
        pollListener?.remove()
        roomListener = nil
        contributionListener = nil
        pollListener = nil
    }

    private func generateCode() -> String {
        String((0..<6).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
    }
}
