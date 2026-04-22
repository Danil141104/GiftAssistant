import Foundation

struct PollOption: Identifiable, Codable {
    var id: String = UUID().uuidString
    var roomID: String
    var name: String
    var votes: Int = 0
    var voterIDs: [String] = []
}
