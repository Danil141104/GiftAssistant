import Foundation

struct GiftItem: Identifiable, Codable {
    let id: String
    let name: String
    let category: String
    let price: Double
    let ageMin: Int
    let ageMax: Int
    let tags: [String]
    let imageURL: String?
    let purchaseURL: String?
    let description: String
    let source: String
}
