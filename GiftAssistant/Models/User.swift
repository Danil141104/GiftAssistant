import Foundation

struct AppUser: Identifiable, Codable {
    var id: String = UUID().uuidString
    var email: String
    var displayName: String
    var createdAt: Date = Date()
}
