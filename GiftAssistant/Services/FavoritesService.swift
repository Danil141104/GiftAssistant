import Foundation
import Combine

@MainActor
class FavoritesService: ObservableObject {
    @Published var favorites: [GiftItem] = []
    
    private let key = "savedFavorites"
    
    init() {
        loadFromDisk()
    }
    
    func isFavorite(_ gift: GiftItem) -> Bool {
        favorites.contains { $0.id == gift.id }
    }
    
    func toggle(_ gift: GiftItem) {
        if isFavorite(gift) {
            favorites.removeAll { $0.id == gift.id }
        } else {
            favorites.append(gift)
        }
        saveToDisk()
    }
    
    func remove(_ gift: GiftItem) {
        favorites.removeAll { $0.id == gift.id }
        saveToDisk()
    }
    
    private func saveToDisk() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func loadFromDisk() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([GiftItem].self, from: data) {
            favorites = saved
        }
    }
}
