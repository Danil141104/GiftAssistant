import Foundation

struct Recommendation: Identifiable, Codable {
    var id: String = UUID().uuidString
    var giftItem: GiftItem
    var recipientID: String
    var score: Double
    var explanation: String
}
