import Foundation
import FirebaseFirestore
import Combine

// MARK: - Models

struct UserProfile: Identifiable, Codable {
    var id: String
    var email: String
    var displayName: String
    var blacklist: [String] = []
    var gender: String = "Other"
    var age: Int = 0
    var birthday: Date? = nil

    var birthdayString: String? {
        guard let birthday else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: birthday)
    }

    var genderString: String {
        switch gender {
        case "Male":   return "Мужской"
        case "Female": return "Женский"
        default:       return "Другой"
        }
    }
}

struct Friendship: Identifiable, Codable {
    var id: String = UUID().uuidString
    var fromUserID: String
    var toUserID: String
    var status: String
    var createdAt: Date = Date()
}

// MARK: - FriendshipService

@MainActor
class FriendshipService: ObservableObject {
    @Published var friends: [UserProfile] = []
    @Published var incomingRequests: [UserProfile] = []
    @Published var outgoingRequests: [UserProfile] = []
    @Published var searchResults: [UserProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    // MARK: - Setup current user profile

    func setupProfile(userID: String, email: String, displayName: String) async {
        let ref = db.collection("userProfiles").document(userID)
        let doc = try? await ref.getDocument()
        if doc?.exists == false {
            try? await ref.setData([
                "id": userID,
                "email": email,
                "displayName": displayName,
                "blacklist": [],
                "gender": "Other",
                "age": 0
            ])
        } else {
            try? await ref.updateData(["email": email])
        }
    }

    // MARK: - Sync blacklist

    func syncBlacklist(userID: String, blacklist: [String]) async {
        try? await db.collection("userProfiles").document(userID)
            .updateData(["blacklist": blacklist])
    }

    // MARK: - Start listening

    func startListening(userID: String) {
        stopListening()

        let l1 = db.collection("friendships")
            .whereField("status", isEqualTo: "accepted")
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                Task { await self.reloadFriends(userID: userID, snap: snap) }
            }

        let l2 = db.collection("friendships")
            .whereField("toUserID", isEqualTo: userID)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                Task { await self.reloadIncoming(userID: userID, snap: snap) }
            }

        let l3 = db.collection("friendships")
            .whereField("fromUserID", isEqualTo: userID)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { [weak self] snap, _ in
                guard let self else { return }
                Task { await self.reloadOutgoing(snap: snap) }
            }

        listeners = [l1, l2, l3]
    }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners = []
    }

    // MARK: - Search

    func searchUser(email: String, currentUserID: String) async {
        let trimmed = email.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { searchResults = []; return }
        isLoading = true
        do {
            let snap = try await db.collection("userProfiles")
                .whereField("email", isEqualTo: trimmed)
                .getDocuments()
            searchResults = snap.documents.compactMap { parseProfile($0.data(), exclude: currentUserID) }
        } catch {
            errorMessage = "Ошибка поиска: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Friend requests

    func sendRequest(fromUserID: String, toUser: UserProfile) async {
        let existing = try? await db.collection("friendships")
            .whereField("fromUserID", isEqualTo: fromUserID)
            .whereField("toUserID", isEqualTo: toUser.id)
            .getDocuments()
        if existing?.documents.isEmpty == false { return }

        let f = Friendship(fromUserID: fromUserID, toUserID: toUser.id, status: "pending")
        try? await db.collection("friendships").document(f.id).setData([
            "id": f.id, "fromUserID": f.fromUserID,
            "toUserID": f.toUserID, "status": f.status, "createdAt": f.createdAt
        ])
    }

    func acceptRequest(fromUserID: String, currentUserID: String) async {
        let snap = try? await db.collection("friendships")
            .whereField("fromUserID", isEqualTo: fromUserID)
            .whereField("toUserID", isEqualTo: currentUserID)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        try? await snap?.documents.first?.reference.updateData(["status": "accepted"])
    }

    func declineRequest(fromUserID: String, currentUserID: String) async {
        let snap = try? await db.collection("friendships")
            .whereField("fromUserID", isEqualTo: fromUserID)
            .whereField("toUserID", isEqualTo: currentUserID)
            .getDocuments()
        try? await snap?.documents.first?.reference.delete()
    }

    func removeFriend(friendID: String, currentUserID: String) async {
        let snap1 = try? await db.collection("friendships")
            .whereField("fromUserID", isEqualTo: currentUserID)
            .whereField("toUserID", isEqualTo: friendID).getDocuments()
        let snap2 = try? await db.collection("friendships")
            .whereField("fromUserID", isEqualTo: friendID)
            .whereField("toUserID", isEqualTo: currentUserID).getDocuments()
        for doc in (snap1?.documents ?? []) + (snap2?.documents ?? []) {
            try? await doc.reference.delete()
        }
    }

    func getFriendBlacklist(friendID: String) async -> [String] {
        let doc = try? await db.collection("userProfiles").document(friendID).getDocument()
        return doc?.data()?["blacklist"] as? [String] ?? []
    }

    func relationStatus(with userID: String, currentUserID: String) -> String {
        if friends.contains(where: { $0.id == userID }) { return "friends" }
        if outgoingRequests.contains(where: { $0.id == userID }) { return "pending_sent" }
        if incomingRequests.contains(where: { $0.id == userID }) { return "pending_received" }
        return "none"
    }

    // MARK: - Private helpers

    private func reloadFriends(userID: String, snap: QuerySnapshot?) async {
        guard let snap else { return }
        var profiles: [UserProfile] = []
        for doc in snap.documents {
            let data = doc.data()
            guard let from = data["fromUserID"] as? String,
                  let to = data["toUserID"] as? String else { continue }
            guard from == userID || to == userID else { continue }
            let friendID = from == userID ? to : from
            if let profile = await fetchProfile(friendID) { profiles.append(profile) }
        }
        friends = profiles
    }

    private func reloadIncoming(userID: String, snap: QuerySnapshot?) async {
        guard let snap else { return }
        var profiles: [UserProfile] = []
        for doc in snap.documents {
            if let from = doc.data()["fromUserID"] as? String,
               let profile = await fetchProfile(from) { profiles.append(profile) }
        }
        incomingRequests = profiles
    }

    private func reloadOutgoing(snap: QuerySnapshot?) async {
        guard let snap else { return }
        var profiles: [UserProfile] = []
        for doc in snap.documents {
            if let to = doc.data()["toUserID"] as? String,
               let profile = await fetchProfile(to) { profiles.append(profile) }
        }
        outgoingRequests = profiles
    }

    private func fetchProfile(_ userID: String) async -> UserProfile? {
        let doc = try? await db.collection("userProfiles").document(userID).getDocument()
        guard let data = doc?.data() else { return nil }
        return parseProfile(data, exclude: nil)
    }

    private func parseProfile(_ data: [String: Any], exclude: String?) -> UserProfile? {
        guard let id = data["id"] as? String,
              let email = data["email"] as? String,
              let name = data["displayName"] as? String else { return nil }
        if let exclude, id == exclude { return nil }

        var profile = UserProfile(
            id: id,
            email: email,
            displayName: name,
            blacklist: data["blacklist"] as? [String] ?? [],
            gender: data["gender"] as? String ?? "Other",
            age: data["age"] as? Int ?? 0
        )
        if let ts = data["birthday"] as? Timestamp {
            profile.birthday = ts.dateValue()
            // Пересчитываем возраст из даты рождения если age не задан
            if profile.age == 0 {
                profile.age = Calendar.current.dateComponents([.year], from: ts.dateValue(), to: Date()).year ?? 0
            }
        }
        return profile
    }
}
