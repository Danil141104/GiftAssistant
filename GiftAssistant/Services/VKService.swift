import Foundation

// MARK: - VK Service

class VKService {
    
    private let serviceToken = "28948dd728948dd728948dd7772bd4ff602289428948dd74172c1b741135492dfe0907e"
    private let apiVersion = "5.199"
    private let baseURL = "https://api.vk.com/method"
    
    // MARK: - Import public interests by VK profile URL or ID
    
    func importInterests(from profileInput: String) async throws -> VKImportResult {
        let userID = extractUserID(from: profileInput)
        
        // 1. Get user profile fields
        let profile = try await fetchUserProfile(userID: userID)
        
        // 2. Get public groups (optional — ignore errors)
        let groups = (try? await fetchUserGroups(userID: profile.resolvedID)) ?? []
        
        // 3. Aggregate raw text
        let rawInterests = aggregateRawData(profile: profile, groups: groups)
        
        // 4. Map to app tags
        let mappedTags = mapToAppTags(rawInterests)
        
        return VKImportResult(
            displayName: "\(profile.firstName) \(profile.lastName)".trimmingCharacters(in: .whitespaces),
            photoURL: profile.photoURL,
            rawInterests: rawInterests,
            mappedTags: mappedTags
        )
    }
    
    // MARK: - Extract user ID from input
    
    private func extractUserID(from input: String) -> String {
        var cleaned = input.trimmingCharacters(in: .whitespaces)
        
        // https://vk.com/username or https://vk.com/id123
        if cleaned.contains("vk.com/") {
            cleaned = cleaned.components(separatedBy: "vk.com/").last ?? cleaned
        }
        // Remove trailing slashes
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        return cleaned.isEmpty ? input : cleaned
    }
    
    // MARK: - Fetch user profile
    
    private func fetchUserProfile(userID: String) async throws -> VKUserProfile {
        let fields = "interests,music,movies,books,games,activities,about,occupation,personal"
        let urlString = "\(baseURL)/users.get?user_ids=\(userID)&fields=\(fields)&access_token=\(serviceToken)&v=\(apiVersion)"
        
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlString) else {
            throw VKError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(VKUsersResponse.self, from: data)
        
        if let error = response.error {
            throw VKError.apiError(error.errorMsg)
        }
        
        guard let user = response.response?.first else {
            throw VKError.userNotFound
        }
        
        return user
    }
    
    // MARK: - Fetch user groups
    
    private func fetchUserGroups(userID: Int) async throws -> [String] {
        let urlString = "\(baseURL)/groups.get?user_id=\(userID)&extended=1&fields=name&count=100&access_token=\(serviceToken)&v=\(apiVersion)"
        
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(VKGroupsResponse.self, from: data)
        
        return response.response?.items.compactMap { $0.name } ?? []
    }
    
    // MARK: - Aggregate raw text data
    
    private func aggregateRawData(profile: VKUserProfile, groups: [String]) -> [String] {
        var parts: [String] = []
        
        if let v = profile.interests, !v.isEmpty { parts.append(contentsOf: splitField(v)) }
        if let v = profile.music,     !v.isEmpty { parts.append(contentsOf: splitField(v)) }
        if let v = profile.movies,    !v.isEmpty { parts.append(contentsOf: splitField(v)) }
        if let v = profile.books,     !v.isEmpty { parts.append(contentsOf: splitField(v)) }
        if let v = profile.games,     !v.isEmpty { parts.append(contentsOf: splitField(v)) }
        if let v = profile.activities,!v.isEmpty { parts.append(contentsOf: splitField(v)) }
        if let v = profile.about,     !v.isEmpty { parts.append(contentsOf: splitField(v)) }
        
        parts.append(contentsOf: groups)
        
        return Array(Set(parts.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }))
    }
    
    private func splitField(_ field: String) -> [String] {
        field.components(separatedBy: CharacterSet(charactersIn: ",;\n"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Map raw data to app tags
    
    private func mapToAppTags(_ rawData: [String]) -> Set<String> {
        var result = Set<String>()
        
        let mappingRules: [(keywords: [String], tag: String)] = [
            // Техника / Гаджеты
            (["техника", "гаджеты", "электроника", "компьютер", "смартфон", "телефон", "ноутбук", "устройства", "apple", "samsung", "xiaomi"], "Техника"),
            (["гаджет", "девайс", "дрон", "робот", "arduino", "raspberry"], "Гаджеты"),
            
            // Музыка
            (["музыка", "music", "гитара", "пианино", "барабан", "синтезатор", "вокал", "концерт", "рок", "поп", "джаз", "хип-хоп", "rap", "edm", "indie", "folk"], "Музыка"),
            
            // Книги
            (["книги", "чтение", "литература", "книга", "роман", "фантастика", "детектив", "поэзия", "библиотека", "books", "reading"], "Книги"),
            
            // Кулинария
            (["кулинария", "готовка", "еда", "рецепты", "кухня", "гастрономия", "выпечка", "кофе", "чай", "ресторан", "food", "cooking"], "Кулинария"),
            
            // Путешествия
            (["путешествия", "туризм", "путешествие", "travel", "поездки", "страны", "горы", "море", "пляж", "кемпинг", "бэкпекинг"], "Путешествия"),
            
            // Спорт
            (["спорт", "футбол", "баскетбол", "теннис", "бег", "плавание", "велосипед", "хоккей", "волейбол", "sport", "бокс", "единоборства"], "Спорт"),
            
            // Фитнес
            (["фитнес", "тренажёрный", "качалка", "йога", "пилатес", "gym", "fitness", "зож", "здоровый образ"], "Фитнес"),
            
            // Игры
            (["игры", "геймер", "gaming", "playstation", "xbox", "nintendo", "steam", "dota", "cs:go", "minecraft", "fortnite", "игра", "видеоигры"], "Игры"),
            
            // Кино
            (["кино", "фильмы", "сериалы", "cinema", "movies", "аниме", "anime", "netflix", "кинотеатр"], "Кино"),
            
            // Творчество
            (["творчество", "рисование", "живопись", "скетч", "art", "искусство", "дизайн", "рукоделие", "diy", "crafts", "лепка"], "Творчество"),
            
            // Фото
            (["фотография", "фото", "photography", "canon", "nikon", "sony", "instagram", "портрет", "съёмка"], "Фото"),
            
            // Мода
            (["мода", "стиль", "fashion", "одежда", "шопинг", "shopping", "бренды", "аксессуары"], "Мода"),
            
            // Красота
            (["красота", "косметика", "уход", "макияж", "beauty", "skincare", "parfum", "парфюм"], "Красота"),
            
            // Дом
            (["дом", "интерьер", "дизайн интерьера", "уют", "ремонт", "декор", "home", "ikea"], "Дом"),
            
            // Сад / Природа
            (["сад", "огород", "растения", "природа", "цветы", "дача", "garden", "экология"], "Природа"),
            
            // Образование
            (["образование", "учёба", "наука", "исследования", "курсы", "обучение", "education", "университет", "академия"], "Образование"),
            
            // Здоровье
            (["здоровье", "медицина", "психология", "wellness", "здоровый", "витамины", "здоровье"], "Здоровье"),
            
            // Животные
            (["животные", "питомцы", "собака", "кошка", "кот", "pets", "animals", "зоология"], "Животные"),
            
            // Кофе
            (["кофе", "coffee", "specialty", "эспрессо", "латте", "кофейня", "бариста"], "Кофе"),
        ]
        
        let combined = rawData.joined(separator: " ").lowercased()
        
        for rule in mappingRules {
            for keyword in rule.keywords {
                if combined.contains(keyword) {
                    result.insert(rule.tag)
                    break
                }
            }
        }
        
        return result
    }
}

// MARK: - Models

struct VKImportResult {
    let displayName: String
    let photoURL: String?
    let rawInterests: [String]
    let mappedTags: Set<String>
}

struct VKUserProfile: Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let photoURL: String?
    let interests: String?
    let music: String?
    let movies: String?
    let books: String?
    let games: String?
    let activities: String?
    let about: String?
    
    var resolvedID: Int { id }
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName  = "last_name"
        case photoURL  = "photo_200"
        case interests, music, movies, books, games, activities, about
    }
}

struct VKUsersResponse: Codable {
    let response: [VKUserProfile]?
    let error: VKAPIError?
}

struct VKGroupItem: Codable {
    let id: Int?
    let name: String?
}

struct VKGroupsItems: Codable {
    let count: Int?
    let items: [VKGroupItem]
}

struct VKGroupsResponse: Codable {
    let response: VKGroupsItems?
    let error: VKAPIError?
}

struct VKAPIError: Codable {
    let errorCode: Int?
    let errorMsg: String
    enum CodingKeys: String, CodingKey {
        case errorCode = "error_code"
        case errorMsg  = "error_msg"
    }
}

enum VKError: LocalizedError {
    case invalidURL
    case userNotFound
    case apiError(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:       return "Invalid profile URL"
        case .userNotFound:     return "User not found. Check the profile link."
        case .apiError(let msg): return "VK API error: \(msg)"
        case .networkError:     return "Network error. Check your connection."
        }
    }
}
