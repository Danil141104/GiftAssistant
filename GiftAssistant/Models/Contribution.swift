import Foundation

struct Contribution: Identifiable, Codable {
    var id: String = UUID().uuidString
    var roomID: String
    var userID: String
    var userName: String
    var amount: Double
    var createdAt: Date = Date()
}
