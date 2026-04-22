import Foundation

struct Recipient: Identifiable, Codable {
    var id: String = UUID().uuidString
    var userID: String
    var name: String
    var gender: String
    var age: Int
    var tags: [String] = []
    var relationship: String
    var birthday: Date? = nil  // дата рождения из контактов
    
    // MARK: - Computed
    
    /// Следующий день рождения (для событий)
    var nextBirthday: Date? {
        guard let birthday else { return nil }
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.month, .day], from: birthday)
        components.year = calendar.component(.year, from: now)
        guard var next = calendar.date(from: components) else { return nil }
        if next < now {
            next = calendar.date(byAdding: .year, value: 1, to: next) ?? next
        }
        return next
    }
    
    /// Строка дня рождения для UI
    var birthdayDisplayString: String? {
        guard let birthday else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: birthday)
    }
}
