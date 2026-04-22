import Foundation
import Combine

@MainActor
class CatalogViewModel: ObservableObject {
    @Published var gifts: [GiftItem] = []
    @Published var filteredGifts: [GiftItem] = []
    @Published var searchText: String = ""
    @Published var selectedTags: Set<String> = []
    @Published var selectedCategory: String? = nil
    @Published var priceMin: Double = 0
    @Published var priceMax: Double = 30000
    @Published var showPriceFilter: Bool = false
    @Published var isLoading: Bool = false

    private let storeAPI = StoreAPIService()

    // MARK: - Cache key
    private static let cacheKey = "cached_gifts"
    private static let cacheTimestampKey = "cached_gifts_timestamp"
    private static let cacheTTL: TimeInterval = 60 * 60 * 24 // 24 часа

    func loadGifts() {
        // Если подарки уже загружены — не грузим снова
        if !gifts.isEmpty { return }

        // Пробуем загрузить из кэша
        if let cached = loadFromCache() {
            gifts = cached
            applyFilters()
            return
        }

        // Грузим из сети/файла
        Task {
            isLoading = true
            let loaded = await storeAPI.fetchAllGifts()
            gifts = loaded
            applyFilters()
            isLoading = false
            saveToCache(loaded)
        }
    }

    func forceReload() {
        clearCache()
        gifts = []
        Task {
            isLoading = true
            let loaded = await storeAPI.fetchAllGifts()
            gifts = loaded
            applyFilters()
            isLoading = false
            saveToCache(loaded)
        }
    }

    // MARK: - Cache

    private func saveToCache(_ gifts: [GiftItem]) {
        guard let data = try? JSONEncoder().encode(gifts) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.cacheTimestampKey)
    }

    private func loadFromCache() -> [GiftItem]? {
        let timestamp = UserDefaults.standard.double(forKey: Self.cacheTimestampKey)
        guard timestamp > 0,
              Date().timeIntervalSince1970 - timestamp < Self.cacheTTL,
              let data = UserDefaults.standard.data(forKey: Self.cacheKey),
              let gifts = try? JSONDecoder().decode([GiftItem].self, from: data),
              !gifts.isEmpty else { return nil }
        print("📦 Catalog loaded from cache: \(gifts.count) gifts")
        return gifts
    }

    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
        UserDefaults.standard.removeObject(forKey: Self.cacheTimestampKey)
    }

    // MARK: - Filters

    func applyFilters() {
        filteredGifts = gifts.filter { gift in
            let matchesSearch = searchText.isEmpty ||
                gift.name.lowercased().contains(searchText.lowercased()) ||
                gift.description.lowercased().contains(searchText.lowercased())
            let matchesTags = selectedTags.isEmpty ||
                !Set(gift.tags.map { $0.lowercased() })
                    .intersection(selectedTags.map { $0.lowercased() })
                    .isEmpty
            let matchesCategory = selectedCategory == nil || gift.category == selectedCategory
            let matchesPrice = gift.price >= priceMin && gift.price <= priceMax
            return matchesSearch && matchesTags && matchesCategory && matchesPrice
        }
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) { selectedTags.remove(tag) }
        else { selectedTags.insert(tag) }
        applyFilters()
    }

    func selectCategory(_ category: String?) {
        selectedCategory = selectedCategory == category ? nil : category
        applyFilters()
    }

    func resetFilters() {
        searchText = ""
        selectedTags = []
        selectedCategory = nil
        priceMin = 0
        priceMax = 30000
        applyFilters()
    }

    var allTags: [String] {
        Array(Set(gifts.flatMap { $0.tags })).sorted()
    }

    var allCategories: [(name: String, icon: String)] {
        let cats = Array(Set(gifts.map { $0.category })).sorted()
        return cats.map { cat in (name: cat, icon: categoryIcon(cat)) }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Техника":     return "desktopcomputer"
        case "Дом":         return "house.fill"
        case "Спорт":       return "figure.run"
        case "Мода":        return "tshirt.fill"
        case "Красота":     return "sparkles"
        case "Книги":       return "book.fill"
        case "Еда":         return "fork.knife"
        case "Игры":        return "gamecontroller.fill"
        case "Творчество":  return "paintbrush.fill"
        case "Впечатления": return "star.fill"
        case "Авто":        return "car.fill"
        case "Животные":    return "pawprint.fill"
        case "Здоровье":    return "heart.fill"
        default:            return "gift"
        }
    }
}
