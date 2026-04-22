import Foundation

struct GroupRoom: Identifiable, Codable {
    var id: String = UUID().uuidString
    var organizerID: String
    var recipientName: String
    var occasion: String
    var targetGiftID: String?
    var budgetGoal: Double
    var currentTotal: Double = 0
    var memberIDs: [String] = []
    var inviteCode: String
    var status: String = "open"
    var createdAt: Date = Date()
}
