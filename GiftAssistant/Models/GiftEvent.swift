import Foundation

struct GiftEvent: Identifiable, Codable {
    var id: String = UUID().uuidString
    var userID: String
    var recipientID: String
    var recipientName: String
    var occasion: String
    var date: Date
    var budgetMin: Double
    var budgetMax: Double
    var notifyEnabled: Bool = true
    var contactID: String? = nil  // привязка к контакту (CNContact.identifier)
}
