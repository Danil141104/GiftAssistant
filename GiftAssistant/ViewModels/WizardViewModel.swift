import Foundation
import Combine
import FirebaseFirestore

@MainActor
class WizardViewModel: ObservableObject {
    @Published var selectedOccasion = ""
    @Published var selectedRecipient: Recipient?
    @Published var budgetMin: Double = 500
    @Published var budgetMax: Double = 5000
    @Published var selectedTags: Set<String> = []
    @Published var recommendations: [Recommendation] = []
    @Published var isLoading = false

    // Voice input
    @Published var voiceAppliedFields: Set<String> = []

    // Friends
    @Published var selectedFriendID: String? = nil
    @Published var friendBlacklist: [String] = []

    private let engine = RecommendationEngine()
    private let storeAPI = StoreAPIService()
    private let db = Firestore.firestore()

    let occasions = [
        "День рождения", "Новый год", "Свадьба", "Юбилей",
        "Выпускной", "8 марта", "23 февраля", "Корпоратив", "Просто так"
    ]

    // MARK: - Select friend and load their interests

    func selectFriendWithInterests(_ friendID: String) {
        selectedFriendID = friendID
        Task { await loadFriendInterests(friendID: friendID) }
    }

    private func loadFriendInterests(friendID: String) async {
        guard let data = try? await db.collection("userInterests")
            .document(friendID).getDocument().data(),
              let tags = data["tags"] as? [String] else { return }

        // Добавляем интересы друга в selectedTags
        tags.forEach { selectedTags.insert($0) }

        // Также добавляем в recipient.tags
        if var recipient = selectedRecipient {
            let merged = Array(Set(recipient.tags + tags))
            recipient.tags = merged
            selectedRecipient = recipient
        }
    }

    // MARK: - Generate recommendations

    func generateRecommendations(blacklist: [String] = []) {
        guard let recipient = selectedRecipient else { return }
        isLoading = true

        let combinedBlacklist = Array(Set(blacklist + friendBlacklist))

        Task {
            let allGifts = await storeAPI.fetchAllGifts()
            var enrichedRecipient = recipient
            enrichedRecipient.tags = Array(Set(recipient.tags + Array(selectedTags)))

            recommendations = engine.recommend(
                gifts: allGifts,
                recipient: enrichedRecipient,
                occasion: selectedOccasion,
                budgetMin: budgetMin,
                budgetMax: budgetMax,
                blacklist: combinedBlacklist
            )
            isLoading = false
        }
    }

    // MARK: - Apply Voice Input

    @discardableResult
    func applyVoiceInput(_ result: VoiceInputResult, userID: String) -> Recipient? {
        voiceAppliedFields = []

        if let occasion = result.occasion, occasions.contains(occasion) {
            selectedOccasion = occasion
            voiceAppliedFields.insert("occasion")
        }
        if let min = result.budgetMin { budgetMin = min; voiceAppliedFields.insert("budget") }
        if let max = result.budgetMax { budgetMax = max; voiceAppliedFields.insert("budget") }
        if !result.tags.isEmpty { result.tags.forEach { selectedTags.insert($0) }; voiceAppliedFields.insert("tags") }

        let hasRecipientData = result.name != nil || result.gender != nil || result.age != nil || result.relationship != nil
        guard hasRecipientData else { return nil }

        let recipient = Recipient(
            userID: userID,
            name: result.name ?? "Без имени",
            gender: result.gender ?? "Other",
            age: result.age ?? 0,
            relationship: result.relationship ?? ""
        )
        selectedRecipient = recipient
        voiceAppliedFields.insert("recipient")
        return recipient
    }

    func reset() {
        selectedOccasion = ""
        selectedRecipient = nil
        budgetMin = 500
        budgetMax = 5000
        selectedTags = []
        recommendations = []
        voiceAppliedFields = []
        selectedFriendID = nil
        friendBlacklist = []
    }
}
