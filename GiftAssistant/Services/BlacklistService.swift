import Foundation
import Combine

@MainActor
class BlacklistService: ObservableObject {
    @Published var blacklist: [String] = []
    
    private let key = "giftBlacklist"
    
    init() {
        loadFromDisk()
    }
    
    func isBlacklisted(_ giftName: String) -> Bool {
        blacklist.contains { giftName.lowercased().contains($0.lowercased()) }
    }
    
    func add(_ item: String) {
        let trimmed = item.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if !blacklist.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
            blacklist.append(trimmed)
            saveToDisk()
        }
    }
    
    func remove(at offsets: IndexSet) {
            for index in offsets.sorted().reversed() {
                blacklist.remove(at: index)
            }
            saveToDisk()
        }
    
    func removeItem(_ item: String) {
        blacklist.removeAll { $0 == item }
        saveToDisk()
    }
    
    private func saveToDisk() {
        UserDefaults.standard.set(blacklist, forKey: key)
    }
    
    private func loadFromDisk() {
        blacklist = UserDefaults.standard.stringArray(forKey: key) ?? []
    }
}
