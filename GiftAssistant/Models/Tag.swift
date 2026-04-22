import Foundation

struct Tag: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var label: String
    var category: String
}
