import Foundation
import FirebaseFirestore
import Combine

@MainActor
class InterestsService: ObservableObject {
    @Published var selectedInterests: Set<String> = []
    @Published var isLoading = false
    
    private let firebase = FirebaseService()
    private let collection = "userInterests"
    
    // MARK: - All available interest categories
    
    static let allCategories: [(icon: String, name: String, tags: [String])] = [
        ("gamecontroller.fill",     "Игры",          ["Игры", "Развлечения", "Геймер"]),
        ("music.note",              "Музыка",         ["Музыка", "Наушники", "Аудио"]),
        ("book.fill",               "Книги",          ["Книги", "Образование", "Чтение"]),
        ("sportscourt.fill",        "Спорт",          ["Спорт", "Фитнес", "Активность"]),
        ("fork.knife",              "Кулинария",      ["Кулинария", "Еда", "Готовка"]),
        ("airplane",                "Путешествия",    ["Путешествия", "Туризм", "Отдых"]),
        ("iphone",                  "Технологии",     ["Техника", "Гаджеты", "Электроника"]),
        ("paintbrush.fill",         "Творчество",     ["Творчество", "Искусство", "DIY"]),
        ("camera.fill",             "Фото",           ["Фото", "Творчество", "Камера"]),
        ("heart.fill",              "Красота",        ["Красота", "Уход", "Косметика"]),
        ("house.fill",              "Дом и уют",      ["Дом", "Уют", "Интерьер"]),
        ("leaf.fill",               "Природа",        ["Природа", "Сад", "Дача"]),
        ("film.fill",               "Кино",           ["Кино", "Сериалы", "Развлечения"]),
        ("figure.run",              "Фитнес",         ["Фитнес", "Спорт", "Здоровье"]),
        ("cup.and.saucer.fill",     "Кофе и чай",     ["Кофе", "Чай", "Кулинария"]),
        ("tshirt.fill",             "Мода",           ["Мода", "Стиль", "Аксессуары"]),
        ("pawprint.fill",           "Животные",       ["Животные", "Питомцы"]),
        ("graduationcap.fill",      "Образование",    ["Образование", "Развитие", "Книги"]),
    ]
    
    // MARK: - Load
    
    func loadInterests(userID: String) async {
        isLoading = true
        do {
            let doc = try await Firestore.firestore()
                .collection(collection)
                .document(userID)
                .getDocument()
            
            if let data = doc.data(),
               let tags = data["tags"] as? [String] {
                selectedInterests = Set(tags)
            }
        } catch {
            // Нет записи — новый пользователь, это нормально
        }
        isLoading = false
    }
    
    // MARK: - Save
    
    func saveInterests(userID: String) async {
        let tags = Array(selectedInterests)
        do {
            try await Firestore.firestore()
                .collection(collection)
                .document(userID)
                .setData(["tags": tags, "updatedAt": Date()])
        } catch {
            print("InterestsService: save error \(error)")
        }
    }
    
    // MARK: - Toggle
    
    func toggle(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
    
    // MARK: - All tags for selected interests
    
    var allSelectedTags: [String] {
        Self.allCategories
            .filter { selectedInterests.contains($0.name) }
            .flatMap { $0.tags }
    }
}
