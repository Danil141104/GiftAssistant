import Foundation

// MARK: - Wildberries Gift Loader

struct WildberriesGiftLoader {
    
    static func loadGifts() -> [GiftItem] {
        guard let url = Bundle.main.url(forResource: "wb_gifts_final", withExtension: "csv"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("WildberriesGiftLoader: CSV file not found")
            return []
        }
        return parseCSV(content)
    }
    
    private static func parseCSV(_ content: String) -> [GiftItem] {
        var lines = content.components(separatedBy: "\n")
        guard !lines.isEmpty else { return [] }
        lines.removeFirst() // skip header
        
        var gifts: [GiftItem] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            let cols = parseCSVLine(trimmed)
            guard cols.count >= 9 else { continue }
            
            let id       = cols[0]
            let name     = cols[1]
            let category = cols[2]
            let price    = Double(cols[3]) ?? 0
            let ageMin   = Int(cols[4]) ?? 14
            let ageMax   = Int(cols[5]) ?? 65
            let tags     = cols[6].components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            // cols[7] = brand
            let imageURL: String? = nil
            
            guard !name.isEmpty, !category.isEmpty, price > 0 else { continue }
            
            let gift = GiftItem(
                id: "wb_\(id)",
                name: name,
                category: category,
                price: price,
                ageMin: ageMin,
                ageMax: ageMax,
                tags: tags,
                imageURL: imageURL,
                purchaseURL: Shop.wildberries.searchURL(for: name),
                description: "Товар с Wildberries",
                source: "wildberries"
            )
            gifts.append(gift)
        }
        
        print("WildberriesGiftLoader: loaded \(gifts.count) gifts")
        return gifts
    }
    
    private static func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let ch = line[i]
            if ch == "\"" {
                if inQuotes && line.index(after: i) < line.endIndex && line[line.index(after: i)] == "\"" {
                    current.append("\"")
                    i = line.index(after: i)
                } else {
                    inQuotes.toggle()
                }
            } else if ch == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(ch)
            }
            i = line.index(after: i)
        }
        result.append(current)
        return result
    }
}
