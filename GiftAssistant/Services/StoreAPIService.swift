import Foundation

// MARK: - DummyJSON Models
struct DummyJSONResponse: Codable {
    let products: [DummyProduct]
}

struct DummyProduct: Codable {
    let id: Int
    let title: String
    let description: String
    let price: Double
    let category: String
    let thumbnail: String
    
    func toGiftItem() -> GiftItem {
        let mapped = CategoryMapper.map(category)
        return GiftItem(
            id: "api_\(id)",
            name: title,
            category: mapped.category,
            price: min(price * 90, 30000),
            ageMin: mapped.ageMin,
            ageMax: mapped.ageMax,
            tags: mapped.tags,
            imageURL: thumbnail,
            purchaseURL: Shop.ozon.searchURL(for: title),
            description: description,
            source: "dummyjson"
        )
    }
}

// MARK: - Category Mapper
struct CategoryMapper {
    struct Mapped {
        let category: String
        let tags: [String]
        let ageMin: Int
        let ageMax: Int
    }
    
    static func map(_ raw: String) -> Mapped {
        switch raw {
        case "smartphones", "laptops", "tablets", "mobile-accessories":
            return Mapped(category: "Техника", tags: ["Техника", "Гаджеты"], ageMin: 14, ageMax: 55)
        case "fragrances", "skincare", "beauty":
            return Mapped(category: "Красота", tags: ["Красота", "Уход"], ageMin: 16, ageMax: 65)
        case "groceries", "food":
            return Mapped(category: "Еда", tags: ["Еда", "Кулинария"], ageMin: 18, ageMax: 70)
        case "home-decoration", "furniture", "lighting", "kitchen-accessories":
            return Mapped(category: "Дом", tags: ["Дом", "Уют"], ageMin: 20, ageMax: 70)
        case "sports-accessories":
            return Mapped(category: "Спорт", tags: ["Спорт", "Фитнес"], ageMin: 14, ageMax: 55)
        case "mens-shirts", "mens-shoes", "mens-watches":
            return Mapped(category: "Мода", tags: ["Мода", "Стиль"], ageMin: 18, ageMax: 55)
        case "womens-dresses", "womens-shoes", "womens-bags", "womens-jewellery", "womens-watches":
            return Mapped(category: "Мода", tags: ["Мода", "Стиль"], ageMin: 18, ageMax: 55)
        case "sunglasses", "tops":
            return Mapped(category: "Мода", tags: ["Мода", "Аксессуары"], ageMin: 16, ageMax: 50)
        case "motorcycle", "vehicle":
            return Mapped(category: "Авто", tags: ["Авто", "Путешествия"], ageMin: 18, ageMax: 60)
        default:
            return Mapped(category: "Другое", tags: ["Подарки"], ageMin: 14, ageMax: 65)
        }
    }
}

// MARK: - Shop
enum Shop: String, CaseIterable {
    case ozon = "Ozon"
    case wildberries = "Wildberries"
    case yandex = "Яндекс Маркет"
    
    var icon: String {
        switch self {
        case .ozon: return "bag.fill"
        case .wildberries: return "flame.fill"
        case .yandex: return "cart.fill"
        }
    }
    
    func searchURL(for query: String) -> String {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        switch self {
        case .ozon: return "https://www.ozon.ru/search/?text=\(encoded)"
        case .wildberries: return "https://www.wildberries.ru/catalog/0/search.aspx?search=\(encoded)"
        case .yandex: return "https://market.yandex.ru/search?text=\(encoded)"
        }
    }
}

// MARK: - StoreAPIService
class StoreAPIService {
    
    private let apiURL = "https://dummyjson.com/products?limit=194"
    
    func fetchAllGifts() async -> [GiftItem] {
        let wb    = WildberriesGiftLoader.loadGifts()
        let api   = await fetchAPIGifts()
        print("📦 Gifts loaded: wb=\(wb.count), api=\(api.count), total=\(wb.count + api.count)")
        return wb + api
    }
    
    func fetchAPIGifts() async -> [GiftItem] {
        guard let url = URL(string: apiURL) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(DummyJSONResponse.self, from: data)
            return response.products.map { $0.toGiftItem() }
        } catch {
            return []
        }
    }
    
    func loadLocalGifts() -> [GiftItem] {
        return LocalGiftData.gifts
    }
    
    func searchGifts(query: String, minPrice: Double?, maxPrice: Double?) async throws -> [GiftItem] {
        let all = await fetchAllGifts()
        return all.filter { gift in
            let matchesQuery = query.isEmpty ||
                gift.name.lowercased().contains(query.lowercased()) ||
                gift.tags.contains { $0.lowercased().contains(query.lowercased()) }
            let matchesMin = minPrice == nil || gift.price >= minPrice!
            let matchesMax = maxPrice == nil || gift.price <= maxPrice!
            return matchesQuery && matchesMin && matchesMax
        }
    }
}

// MARK: - Local Gift Data (80 curated gifts)
struct LocalGiftData {
    static let gifts: [GiftItem] = [
        GiftItem(id: "local_1", name: "Беспроводные наушники", category: "Техника", price: 3500, ageMin: 14, ageMax: 55, tags: ["Техника", "Музыка"], imageURL: "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400", purchaseURL: nil, description: "Качественные наушники с шумоподавлением", source: "local"),
        GiftItem(id: "local_2", name: "Портативная колонка", category: "Техника", price: 4200, ageMin: 14, ageMax: 50, tags: ["Техника", "Музыка"], imageURL: "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=400", purchaseURL: nil, description: "Водонепроницаемая Bluetooth-колонка", source: "local"),
        GiftItem(id: "local_3", name: "Умные часы", category: "Техника", price: 8500, ageMin: 16, ageMax: 55, tags: ["Техника", "Фитнес", "Гаджеты"], imageURL: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400", purchaseURL: nil, description: "Фитнес-трекер с пульсометром и GPS", source: "local"),
        GiftItem(id: "local_4", name: "Электронная книга", category: "Техника", price: 12000, ageMin: 14, ageMax: 70, tags: ["Техника", "Книги"], imageURL: "https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=400", purchaseURL: nil, description: "E-ink экран, встроенная подсветка", source: "local"),
        GiftItem(id: "local_5", name: "Фитнес-браслет", category: "Техника", price: 2800, ageMin: 14, ageMax: 60, tags: ["Техника", "Фитнес", "Спорт"], imageURL: "https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?w=400", purchaseURL: nil, description: "Шагомер, пульс, сон, уведомления", source: "local"),
        GiftItem(id: "local_6", name: "Моментальная камера", category: "Техника", price: 7500, ageMin: 14, ageMax: 50, tags: ["Техника", "Фото", "Творчество"], imageURL: "https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=400", purchaseURL: nil, description: "Ретро-камера с моментальной печатью", source: "local"),
        GiftItem(id: "local_7", name: "Настольная лампа с зарядкой", category: "Техника", price: 3200, ageMin: 16, ageMax: 60, tags: ["Техника", "Дом"], imageURL: "https://images.unsplash.com/photo-1507473885765-e6ed057ab6fe?w=400", purchaseURL: nil, description: "LED-лампа с беспроводной зарядкой", source: "local"),
        GiftItem(id: "local_8", name: "Портативный проектор", category: "Техника", price: 14000, ageMin: 16, ageMax: 55, tags: ["Техника", "Развлечения", "Кино"], imageURL: "https://images.unsplash.com/photo-1478720568477-152d9b164e26?w=400", purchaseURL: nil, description: "Мини-проектор для фильмов, Wi-Fi", source: "local"),
        GiftItem(id: "local_9", name: "Механическая клавиатура", category: "Техника", price: 5500, ageMin: 14, ageMax: 45, tags: ["Техника", "Игры", "Гаджеты"], imageURL: "https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=400", purchaseURL: nil, description: "RGB-подсветка, тактильные переключатели", source: "local"),
        GiftItem(id: "local_10", name: "Повербанк 20000 mAh", category: "Техника", price: 2500, ageMin: 14, ageMax: 65, tags: ["Техника", "Путешествия", "Гаджеты"], imageURL: "https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=400", purchaseURL: nil, description: "Быстрая зарядка, 2 USB + Type-C", source: "local"),
        GiftItem(id: "local_11", name: "Умная колонка с Алисой", category: "Техника", price: 6000, ageMin: 14, ageMax: 65, tags: ["Техника", "Дом", "Музыка"], imageURL: "https://images.unsplash.com/photo-1543512214-318228f18c30?w=400", purchaseURL: nil, description: "Голосовой помощник, музыка, умный дом", source: "local"),
        GiftItem(id: "local_12", name: "Электрическая зубная щётка", category: "Техника", price: 4500, ageMin: 16, ageMax: 65, tags: ["Техника", "Здоровье", "Уход"], imageURL: "https://images.unsplash.com/photo-1559590185-4f4085804c9e?w=400", purchaseURL: nil, description: "Звуковая, 5 режимов, дорожный футляр", source: "local"),
        GiftItem(id: "local_13", name: "Ароматические свечи (набор)", category: "Дом", price: 1800, ageMin: 18, ageMax: 70, tags: ["Дом", "Уют", "Красота"], imageURL: "https://images.unsplash.com/photo-1602607753066-4a97f081a687?w=400", purchaseURL: nil, description: "3 свечи: лаванда, ваниль, кедр", source: "local"),
        GiftItem(id: "local_14", name: "Плед из мериноса", category: "Дом", price: 5500, ageMin: 18, ageMax: 70, tags: ["Дом", "Уют"], imageURL: "https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400", purchaseURL: nil, description: "Мягкий тёплый плед 150x200 см", source: "local"),
        GiftItem(id: "local_15", name: "Кофемашина капсульная", category: "Дом", price: 9500, ageMin: 20, ageMax: 65, tags: ["Дом", "Кулинария", "Кофе"], imageURL: "https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?w=400", purchaseURL: nil, description: "Автоматическая, поддержка нескольких капсул", source: "local"),
        GiftItem(id: "local_16", name: "Комнатные растения (набор)", category: "Дом", price: 2200, ageMin: 18, ageMax: 70, tags: ["Дом", "Сад", "Уют"], imageURL: "https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=400", purchaseURL: nil, description: "3 неприхотливых растения в горшках", source: "local"),
        GiftItem(id: "local_17", name: "Аромадиффузор", category: "Дом", price: 2800, ageMin: 18, ageMax: 70, tags: ["Дом", "Уют", "Красота"], imageURL: "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=400", purchaseURL: nil, description: "Ультразвуковой с LED-подсветкой + 3 масла", source: "local"),
        GiftItem(id: "local_18", name: "Набор кухонных ножей", category: "Дом", price: 4800, ageMin: 20, ageMax: 65, tags: ["Дом", "Кулинария"], imageURL: "https://images.unsplash.com/photo-1593618998160-e34014e67546?w=400", purchaseURL: nil, description: "5 ножей + подставка, нержавеющая сталь", source: "local"),
        GiftItem(id: "local_19", name: "Декоративные подушки (2 шт)", category: "Дом", price: 2400, ageMin: 18, ageMax: 70, tags: ["Дом", "Уют"], imageURL: "https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?w=400", purchaseURL: nil, description: "Бархатные, 45x45 см, стильный дизайн", source: "local"),
        GiftItem(id: "local_20", name: "Настенные часы", category: "Дом", price: 3500, ageMin: 18, ageMax: 70, tags: ["Дом", "Стиль"], imageURL: "https://images.unsplash.com/photo-1563861826100-9cb868fdbe1c?w=400", purchaseURL: nil, description: "Минималистичный дизайн, бесшумный механизм", source: "local"),
        GiftItem(id: "local_21", name: "Набор бокалов для вина", category: "Дом", price: 3200, ageMin: 21, ageMax: 70, tags: ["Дом", "Кулинария"], imageURL: "https://images.unsplash.com/photo-1516594798947-e65505dbb29d?w=400", purchaseURL: nil, description: "6 бокалов из хрустального стекла", source: "local"),
        GiftItem(id: "local_22", name: "Вафельница", category: "Дом", price: 2600, ageMin: 16, ageMax: 65, tags: ["Дом", "Кулинария", "Еда"], imageURL: "https://images.unsplash.com/photo-1568051243858-533a607809a5?w=400", purchaseURL: nil, description: "Антипригарное покрытие, венские вафли", source: "local"),
        GiftItem(id: "local_23", name: "Набор для рисования", category: "Творчество", price: 2800, ageMin: 10, ageMax: 70, tags: ["Творчество", "DIY"], imageURL: "https://images.unsplash.com/photo-1513364776144-60967b0f800f?w=400", purchaseURL: nil, description: "Карандаши, краски, кисти — 48 предметов", source: "local"),
        GiftItem(id: "local_24", name: "Набор для выращивания трав", category: "Творчество", price: 1500, ageMin: 12, ageMax: 70, tags: ["Сад", "DIY", "Кулинария"], imageURL: "https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?w=400", purchaseURL: nil, description: "Базилик, мята, розмарин — семена + горшки", source: "local"),
        GiftItem(id: "local_25", name: "Набор для вышивания", category: "Творчество", price: 1200, ageMin: 14, ageMax: 70, tags: ["Творчество", "DIY"], imageURL: "https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=400", purchaseURL: nil, description: "Схема, нитки, канва — всё включено", source: "local"),
        GiftItem(id: "local_26", name: "Конструктор LEGO Architecture", category: "Творчество", price: 6500, ageMin: 14, ageMax: 99, tags: ["Творчество", "DIY", "Игры"], imageURL: "https://images.unsplash.com/photo-1587654780291-39c9404d7dd0?w=400", purchaseURL: nil, description: "Модель здания из 1000+ деталей", source: "local"),
        GiftItem(id: "local_27", name: "Набор для мыловарения", category: "Творчество", price: 1800, ageMin: 14, ageMax: 60, tags: ["Творчество", "DIY", "Красота"], imageURL: "https://images.unsplash.com/photo-1607006344380-b6775a0824a7?w=400", purchaseURL: nil, description: "Основа, красители, формы, ароматизаторы", source: "local"),
        GiftItem(id: "local_28", name: "Скетчбук премиум", category: "Творчество", price: 1400, ageMin: 12, ageMax: 60, tags: ["Творчество", "DIY"], imageURL: "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400", purchaseURL: nil, description: "A4, 200 страниц, для маркеров", source: "local"),
        GiftItem(id: "local_29", name: "Набор для каллиграфии", category: "Творчество", price: 2200, ageMin: 14, ageMax: 65, tags: ["Творчество", "DIY", "Образование"], imageURL: "https://images.unsplash.com/photo-1455390582262-044cdead277a?w=400", purchaseURL: nil, description: "Перья, тушь, прописи, бумага", source: "local"),
        GiftItem(id: "local_30", name: "Алмазная мозаика", category: "Творчество", price: 1600, ageMin: 12, ageMax: 70, tags: ["Творчество", "DIY"], imageURL: "https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400", purchaseURL: nil, description: "40x50 см, всё включено", source: "local"),
        GiftItem(id: "local_31", name: "Рюкзак для путешествий", category: "Спорт", price: 5200, ageMin: 16, ageMax: 55, tags: ["Путешествия", "Спорт"], imageURL: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400", purchaseURL: nil, description: "40л, водонепроницаемый", source: "local"),
        GiftItem(id: "local_32", name: "Коврик для йоги", category: "Спорт", price: 2500, ageMin: 16, ageMax: 65, tags: ["Спорт", "Фитнес", "Здоровье"], imageURL: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400", purchaseURL: nil, description: "Нескользящий, экологичный", source: "local"),
        GiftItem(id: "local_33", name: "Термос 750мл", category: "Спорт", price: 2200, ageMin: 14, ageMax: 65, tags: ["Путешествия", "Спорт"], imageURL: "https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400", purchaseURL: nil, description: "Тепло 12 часов, холод 24 часа", source: "local"),
        GiftItem(id: "local_34", name: "Гантели разборные", category: "Спорт", price: 4500, ageMin: 16, ageMax: 55, tags: ["Спорт", "Фитнес"], imageURL: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400", purchaseURL: nil, description: "От 2 до 10 кг каждая", source: "local"),
        GiftItem(id: "local_35", name: "Палатка 2-местная", category: "Спорт", price: 8900, ageMin: 18, ageMax: 55, tags: ["Путешествия", "Спорт"], imageURL: "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=400", purchaseURL: nil, description: "Быстрая сборка, водостойкая", source: "local"),
        GiftItem(id: "local_36", name: "Скакалка скоростная", category: "Спорт", price: 800, ageMin: 10, ageMax: 55, tags: ["Спорт", "Фитнес"], imageURL: "https://images.unsplash.com/photo-1434596922112-19cb7ffc3fd0?w=400", purchaseURL: nil, description: "Подшипники, регулируемая длина", source: "local"),
        GiftItem(id: "local_37", name: "Спортивная бутылка 1л", category: "Спорт", price: 1200, ageMin: 10, ageMax: 65, tags: ["Спорт", "Фитнес", "Здоровье"], imageURL: "https://images.unsplash.com/photo-1523362628745-0c100150b504?w=400", purchaseURL: nil, description: "Тритан, шкала объёма, без BPA", source: "local"),
        GiftItem(id: "local_38", name: "Дорожный органайзер", category: "Спорт", price: 1800, ageMin: 18, ageMax: 65, tags: ["Путешествия", "Стиль"], imageURL: "https://images.unsplash.com/photo-1553531384-411a247ccd73?w=400", purchaseURL: nil, description: "6 секций для одежды и аксессуаров", source: "local"),
        GiftItem(id: "local_39", name: "Эспандер набор (5 шт)", category: "Спорт", price: 1500, ageMin: 14, ageMax: 60, tags: ["Спорт", "Фитнес"], imageURL: "https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=400", purchaseURL: nil, description: "5 уровней нагрузки + мешочек", source: "local"),
        GiftItem(id: "local_40", name: "Бинокль компактный", category: "Спорт", price: 3800, ageMin: 14, ageMax: 70, tags: ["Путешествия", "Спорт"], imageURL: "https://images.unsplash.com/photo-1502982720700-bfff97f2ecac?w=400", purchaseURL: nil, description: "10x25, складной, чехол", source: "local"),
        GiftItem(id: "local_41", name: "Подарочный набор книг", category: "Книги", price: 3200, ageMin: 14, ageMax: 70, tags: ["Книги", "Образование"], imageURL: "https://images.unsplash.com/photo-1512820790803-83ca734da794?w=400", purchaseURL: nil, description: "3 бестселлера в подарочной упаковке", source: "local"),
        GiftItem(id: "local_42", name: "Онлайн-курс (сертификат)", category: "Книги", price: 4500, ageMin: 16, ageMax: 60, tags: ["Образование", "Творчество"], imageURL: "https://images.unsplash.com/photo-1501504905252-473c47e087f8?w=400", purchaseURL: nil, description: "Языки, дизайн, код — 50+ курсов", source: "local"),
        GiftItem(id: "local_43", name: "Кулинарная книга", category: "Книги", price: 1800, ageMin: 18, ageMax: 70, tags: ["Книги", "Кулинария"], imageURL: "https://images.unsplash.com/photo-1466637574441-749b8f19452f?w=400", purchaseURL: nil, description: "200+ рецептов с фото", source: "local"),
        GiftItem(id: "local_44", name: "Ежедневник-планер", category: "Книги", price: 1400, ageMin: 16, ageMax: 65, tags: ["Книги", "Образование", "Стиль"], imageURL: "https://images.unsplash.com/photo-1531346878377-a5be20888e57?w=400", purchaseURL: nil, description: "Кожаная обложка, 365 дней", source: "local"),
        GiftItem(id: "local_45", name: "Подписка на аудиокниги", category: "Книги", price: 2400, ageMin: 14, ageMax: 70, tags: ["Книги", "Развлечения", "Образование"], imageURL: "https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=400", purchaseURL: nil, description: "6 месяцев безлимита", source: "local"),
        GiftItem(id: "local_46", name: "Глобус с подсветкой", category: "Книги", price: 3500, ageMin: 10, ageMax: 70, tags: ["Образование", "Дом"], imageURL: "https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=400", purchaseURL: nil, description: "25 см, LED, политическая карта", source: "local"),
        GiftItem(id: "local_47", name: "Набор уходовой косметики", category: "Красота", price: 3500, ageMin: 18, ageMax: 65, tags: ["Красота", "Уход"], imageURL: "https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=400", purchaseURL: nil, description: "Крем, сыворотка, маска — коробка", source: "local"),
        GiftItem(id: "local_48", name: "Парфюм подарочный", category: "Красота", price: 6500, ageMin: 18, ageMax: 65, tags: ["Красота", "Стиль"], imageURL: "https://images.unsplash.com/photo-1541643600914-78b084683601?w=400", purchaseURL: nil, description: "Элегантный аромат, 50мл", source: "local"),
        GiftItem(id: "local_49", name: "Массажная подушка", category: "Красота", price: 3800, ageMin: 20, ageMax: 70, tags: ["Здоровье", "Уход", "Дом"], imageURL: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=400", purchaseURL: nil, description: "Шиацу-массаж, подогрев", source: "local"),
        GiftItem(id: "local_50", name: "Бомбочки для ванны (8 шт)", category: "Красота", price: 1400, ageMin: 16, ageMax: 60, tags: ["Красота", "Уход"], imageURL: "https://images.unsplash.com/photo-1570194065650-d99fb4a38018?w=400", purchaseURL: nil, description: "С эфирными маслами, в коробке", source: "local"),
        GiftItem(id: "local_51", name: "Шёлковая маска для сна", category: "Красота", price: 1200, ageMin: 16, ageMax: 65, tags: ["Красота", "Уход", "Здоровье"], imageURL: "https://images.unsplash.com/photo-1596755389378-c31d21fd1273?w=400", purchaseURL: nil, description: "100% шёлк, в чехле", source: "local"),
        GiftItem(id: "local_52", name: "Набор для маникюра", category: "Красота", price: 2200, ageMin: 16, ageMax: 65, tags: ["Красота", "Уход", "Стиль"], imageURL: "https://images.unsplash.com/photo-1604654894610-df63bc536371?w=400", purchaseURL: nil, description: "12 инструментов в кожаном футляре", source: "local"),
        GiftItem(id: "local_53", name: "Расчёска-массажёр", category: "Красота", price: 900, ageMin: 14, ageMax: 65, tags: ["Красота", "Уход"], imageURL: "https://images.unsplash.com/photo-1522338242992-e1a54571a9f7?w=400", purchaseURL: nil, description: "Антистатик, массаж кожи головы", source: "local"),
        GiftItem(id: "local_54", name: "Электрическая пилка для ног", category: "Красота", price: 1800, ageMin: 18, ageMax: 65, tags: ["Красота", "Уход", "Здоровье"], imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400", purchaseURL: nil, description: "USB-зарядка, 2 насадки", source: "local"),
        GiftItem(id: "local_55", name: "Настольная игра Catan", category: "Игры", price: 2400, ageMin: 10, ageMax: 60, tags: ["Игры", "Развлечения"], imageURL: "https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?w=400", purchaseURL: nil, description: "Стратегия для 3-4 игроков", source: "local"),
        GiftItem(id: "local_56", name: "Игровая мышь", category: "Техника", price: 3200, ageMin: 14, ageMax: 45, tags: ["Игры", "Техника", "Гаджеты"], imageURL: "https://images.unsplash.com/photo-1527814050087-3793815479db?w=400", purchaseURL: nil, description: "RGB-подсветка, 6 кнопок", source: "local"),
        GiftItem(id: "local_57", name: "Пазл 1000 деталей", category: "Игры", price: 1200, ageMin: 10, ageMax: 70, tags: ["Игры", "Творчество", "Развлечения"], imageURL: "https://images.unsplash.com/photo-1494059980473-813e73ee784b?w=400", purchaseURL: nil, description: "Красочный пазл с пейзажем", source: "local"),
        GiftItem(id: "local_58", name: "VR-очки", category: "Техника", price: 15000, ageMin: 14, ageMax: 45, tags: ["Игры", "Техника", "Развлечения"], imageURL: "https://images.unsplash.com/photo-1622979135225-d2ba269cf1ac?w=400", purchaseURL: nil, description: "Автономные для игр и видео", source: "local"),
        GiftItem(id: "local_59", name: "Настольная игра Монополия", category: "Игры", price: 2800, ageMin: 8, ageMax: 70, tags: ["Игры", "Развлечения"], imageURL: "https://images.unsplash.com/photo-1640461470346-c8b56497850a?w=400", purchaseURL: nil, description: "Классическая для всей семьи", source: "local"),
        GiftItem(id: "local_60", name: "Карточная игра UNO", category: "Игры", price: 600, ageMin: 7, ageMax: 70, tags: ["Игры", "Развлечения"], imageURL: "https://images.unsplash.com/photo-1606503153255-59d8b8b82176?w=400", purchaseURL: nil, description: "Для 2-10 игроков", source: "local"),
        GiftItem(id: "local_61", name: "Дартс магнитный", category: "Игры", price: 1500, ageMin: 10, ageMax: 60, tags: ["Игры", "Развлечения", "Спорт"], imageURL: "https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=400", purchaseURL: nil, description: "Безопасные магнитные дротики", source: "local"),
        GiftItem(id: "local_62", name: "Набор покер", category: "Игры", price: 3500, ageMin: 18, ageMax: 65, tags: ["Игры", "Развлечения"], imageURL: "https://images.unsplash.com/photo-1541278107931-e006523892df?w=400", purchaseURL: nil, description: "300 фишек, 2 колоды, кейс", source: "local"),
        GiftItem(id: "local_63", name: "Гейм-пад для телефона", category: "Техника", price: 2500, ageMin: 12, ageMax: 40, tags: ["Игры", "Техника", "Гаджеты"], imageURL: "https://images.unsplash.com/photo-1592840496694-26d035b52b48?w=400", purchaseURL: nil, description: "Bluetooth, iOS и Android", source: "local"),
        GiftItem(id: "local_64", name: "Подписка на стриминг (год)", category: "Игры", price: 3000, ageMin: 14, ageMax: 60, tags: ["Развлечения", "Музыка", "Кино"], imageURL: "https://images.unsplash.com/photo-1522869635100-9f4c5e86aa37?w=400", purchaseURL: nil, description: "Кино, музыка или аудиокниги на год", source: "local"),
        GiftItem(id: "local_65", name: "Кожаный кошелёк", category: "Мода", price: 3500, ageMin: 18, ageMax: 65, tags: ["Мода", "Аксессуары", "Стиль"], imageURL: "https://images.unsplash.com/photo-1627123424574-724758594e93?w=400", purchaseURL: nil, description: "Натуральная кожа, подарочная коробка", source: "local"),
        GiftItem(id: "local_66", name: "Шарф кашемировый", category: "Мода", price: 4200, ageMin: 18, ageMax: 70, tags: ["Мода", "Стиль", "Уют"], imageURL: "https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=400", purchaseURL: nil, description: "Нежный кашемировый шарф", source: "local"),
        GiftItem(id: "local_67", name: "Солнцезащитные очки", category: "Мода", price: 2800, ageMin: 16, ageMax: 55, tags: ["Мода", "Аксессуары", "Путешествия"], imageURL: "https://images.unsplash.com/photo-1572635196237-14b3f281503f?w=400", purchaseURL: nil, description: "UV400, стильный дизайн", source: "local"),
        GiftItem(id: "local_68", name: "Ремень кожаный", category: "Мода", price: 2400, ageMin: 18, ageMax: 65, tags: ["Мода", "Аксессуары", "Стиль"], imageURL: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400", purchaseURL: nil, description: "Натуральная кожа, классическая пряжка", source: "local"),
        GiftItem(id: "local_69", name: "Шапка вязаная", category: "Мода", price: 1600, ageMin: 14, ageMax: 55, tags: ["Мода", "Стиль", "Уют"], imageURL: "https://images.unsplash.com/photo-1576871337632-b9aef4c17ab9?w=400", purchaseURL: nil, description: "Шерсть мериноса, тёплая", source: "local"),
        GiftItem(id: "local_70", name: "Запонки в коробке", category: "Мода", price: 2200, ageMin: 25, ageMax: 65, tags: ["Мода", "Аксессуары", "Стиль"], imageURL: "https://images.unsplash.com/photo-1590548784585-643d2b9f2925?w=400", purchaseURL: nil, description: "Нержавеющая сталь, подарочная коробка", source: "local"),
        GiftItem(id: "local_71", name: "Сумка-шоппер", category: "Мода", price: 1800, ageMin: 16, ageMax: 55, tags: ["Мода", "Стиль", "Аксессуары"], imageURL: "https://images.unsplash.com/photo-1544816155-12df9643f363?w=400", purchaseURL: nil, description: "Хлопок, стильный принт", source: "local"),
        GiftItem(id: "local_72", name: "Зонт-автомат", category: "Мода", price: 2000, ageMin: 14, ageMax: 70, tags: ["Мода", "Аксессуары"], imageURL: "https://images.unsplash.com/photo-1534309466160-70b22cc6254d?w=400", purchaseURL: nil, description: "Ветроустойчивый, компактный", source: "local"),
        GiftItem(id: "local_73", name: "Набор крафтового шоколада", category: "Еда", price: 2200, ageMin: 10, ageMax: 70, tags: ["Еда", "Сладости"], imageURL: "https://images.unsplash.com/photo-1481391319762-47dff72954d9?w=400", purchaseURL: nil, description: "8 плиток из разных стран", source: "local"),
        GiftItem(id: "local_74", name: "Чайный набор премиум", category: "Еда", price: 2800, ageMin: 18, ageMax: 70, tags: ["Еда", "Кулинария"], imageURL: "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400", purchaseURL: nil, description: "6 сортов чая в жестяной банке", source: "local"),
        GiftItem(id: "local_75", name: "Набор специй для гриля", category: "Еда", price: 1500, ageMin: 18, ageMax: 65, tags: ["Еда", "Кулинария"], imageURL: "https://images.unsplash.com/photo-1532336414038-cf19250c5757?w=400", purchaseURL: nil, description: "12 специй и маринадов", source: "local"),
        GiftItem(id: "local_76", name: "Кофе в зёрнах (набор)", category: "Еда", price: 2600, ageMin: 18, ageMax: 70, tags: ["Еда", "Кофе", "Кулинария"], imageURL: "https://images.unsplash.com/photo-1559056199-641a0ac8b55e?w=400", purchaseURL: nil, description: "4 сорта из разных стран", source: "local"),
        GiftItem(id: "local_77", name: "Мёд подарочный набор", category: "Еда", price: 1800, ageMin: 10, ageMax: 70, tags: ["Еда", "Сладости"], imageURL: "https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=400", purchaseURL: nil, description: "4 вида мёда в баночках", source: "local"),
        GiftItem(id: "local_78", name: "Набор для суши", category: "Еда", price: 2000, ageMin: 16, ageMax: 60, tags: ["Еда", "Кулинария"], imageURL: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=400", purchaseURL: nil, description: "Коврик, палочки, соусники, рецепты", source: "local"),
        GiftItem(id: "local_79", name: "Сертификат на мастер-класс", category: "Впечатления", price: 5000, ageMin: 14, ageMax: 65, tags: ["Творчество", "Развлечения", "Образование"], imageURL: "https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=400", purchaseURL: nil, description: "Керамика, кулинария или рисование", source: "local"),
        GiftItem(id: "local_80", name: "Сертификат в СПА", category: "Впечатления", price: 7000, ageMin: 18, ageMax: 65, tags: ["Здоровье", "Красота", "Уход"], imageURL: "https://images.unsplash.com/photo-1540555700478-4be289fbec6d?w=400", purchaseURL: nil, description: "2 часа: массаж, сауна, бассейн", source: "local"),
    ]
}
