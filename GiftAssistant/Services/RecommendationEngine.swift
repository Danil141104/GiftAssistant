import Foundation

// MARK: - Recommendation Engine v3

class RecommendationEngine {

    private let weightTags: Double
    private let weightOccasion: Double
    private let weightBudget: Double
    private let weightAge: Double
    private let weightGender: Double

    init(
        weightTags: Double    = 0.50,
        weightOccasion: Double = 0.20,
        weightBudget: Double  = 0.15,
        weightAge: Double     = 0.10,
        weightGender: Double  = 0.05
    ) {
        self.weightTags     = weightTags
        self.weightOccasion = weightOccasion
        self.weightBudget   = weightBudget
        self.weightAge      = weightAge
        self.weightGender   = weightGender
    }

    // MARK: - Tag Mapping

    private let tagMapping: [String: [String]] = [
        "Техника":      ["Техника", "Гаджеты", "Электроника"],
        "Гаджеты":      ["Гаджеты", "Техника", "Электроника"],
        "Музыка":       ["Музыка", "Наушники", "Аудио"],
        "Книги":        ["Книги", "Образование", "Чтение"],
        "Кулинария":    ["Кулинария", "Еда", "Готовка"],
        "Путешествия":  ["Путешествия", "Туризм", "Отдых"],
        "Спорт":        ["Спорт", "Фитнес", "Активный отдых"],
        "Фитнес":       ["Фитнес", "Спорт", "Здоровье"],
        "Мода":         ["Мода", "Стиль", "Аксессуары", "Одежда"],
        "Фото":         ["Фото", "Творчество", "Камера"],
        "Творчество":   ["Творчество", "DIY", "Искусство"],
        "DIY":          ["DIY", "Творчество", "Хобби"],
        "Игры":         ["Игры", "Развлечения", "Геймер"],
        "Развлечения":  ["Развлечения", "Игры", "Досуг"],
        "Красота":      ["Красота", "Уход", "Косметика"],
        "Уход":         ["Уход", "Красота", "Здоровье"],
        "Дом":          ["Дом", "Уют", "Интерьер"],
        "Уют":          ["Уют", "Дом", "Декор"],
        "Сад":          ["Сад", "Природа", "Дача"],
        "Здоровье":     ["Здоровье", "Уход", "Фитнес"],
        "Образование":  ["Образование", "Книги", "Развитие"],
        "Стиль":        ["Стиль", "Мода", "Аксессуары"],
        "Аксессуары":   ["Аксессуары", "Мода", "Стиль"],
        "Еда":          ["Еда", "Кулинария", "Сладости", "Гурман"],
        "Кофе":         ["Кофе", "Кулинария", "Напитки"],
        "Природа":      ["Природа", "Сад", "Экология"],
        "Кино":         ["Кино", "Развлечения", "Сериалы"],
        "Искусство":    ["Искусство", "Творчество", "Культура"],
        "Животные":     ["Животные", "Питомцы"],
    ]

    private let occasionTagBonus: [String: [String]] = [
        "День рождения":  ["Праздник", "Сюрприз", "Развлечения", "Игры"],
        "Новый год":      ["Праздник", "Уют", "Дом", "Сладости", "Игры"],
        "Свадьба":        ["Дом", "Уют", "Красота", "Стиль", "Романтика"],
        "Юбилей":         ["Стиль", "Аксессуары", "Дом", "Путешествия"],
        "8 марта":        ["Красота", "Цветы", "Уход", "Мода", "Романтика"],
        "23 февраля":     ["Спорт", "Техника", "Гаджеты", "Игры"],
        "Выпускной":      ["Образование", "Техника", "Путешествия", "Мода"],
        "Корпоратив":     ["Еда", "Развлечения", "Игры", "Уют"],
        "Просто так":     [],
        "Годовщина":      ["Романтика", "Уют", "Стиль", "Путешествия"],
        "День матери":    ["Красота", "Уход", "Цветы", "Уют", "Кулинария"],
        "День отца":      ["Спорт", "Техника", "Гаджеты", "Кулинария"],
    ]

    private let genderTagBonus: [String: [String]] = [
        "Female": ["Красота", "Уход", "Мода", "Стиль", "Цветы", "Косметика"],
        "Male":   ["Спорт", "Техника", "Гаджеты", "Игры"],
    ]

    private func ageBonusTags(for age: Int) -> [String] {
        switch age {
        case 0...12:  return ["Игры", "Развлечения", "Творчество", "Животные"]
        case 13...17: return ["Игры", "Музыка", "Мода", "Техника", "Творчество"]
        case 18...25: return ["Техника", "Игры", "Музыка", "Путешествия", "Мода"]
        case 26...35: return ["Спорт", "Путешествия", "Кулинария", "Техника", "Дом"]
        case 36...50: return ["Дом", "Уют", "Кулинария", "Здоровье", "Путешествия"]
        case 51...65: return ["Здоровье", "Дом", "Сад", "Кулинария", "Книги"]
        default:      return ["Здоровье", "Уют", "Сад", "Книги"]
        }
    }

    private func expandedTags(from userTags: [String]) -> Set<String> {
        var expanded = Set<String>()
        for tag in userTags {
            expanded.insert(tag.lowercased())
            if let mapped = tagMapping[tag] {
                mapped.forEach { expanded.insert($0.lowercased()) }
            }
        }
        return expanded
    }

    // MARK: - Main Recommend Function

    func recommend(
        gifts: [GiftItem],
        recipient: Recipient,
        occasion: String,
        budgetMin: Double,
        budgetMax: Double,
        blacklist: [String] = []
    ) -> [Recommendation] {

        let directUserTags   = Set(recipient.tags.map { $0.lowercased() })
        let expandedUserTags = expandedTags(from: recipient.tags)
        let genderBonus      = Set((genderTagBonus[recipient.gender] ?? []).map { $0.lowercased() })
        let ageBonus         = Set(ageBonusTags(for: recipient.age).map { $0.lowercased() })
        let occasionBonus    = Set((occasionTagBonus[occasion] ?? []).map { $0.lowercased() })

        var scored: [(gift: GiftItem, score: Double, explanation: [String])] = []

        for gift in gifts {
            // 1. Blacklist
            if blacklist.contains(where: { gift.name.lowercased().contains($0.lowercased()) }) { continue }

            // 2. Бюджет
            guard gift.price >= budgetMin && gift.price <= budgetMax else { continue }

            // 3. Возраст
            if recipient.age > 0 {
                guard recipient.age >= gift.ageMin && recipient.age <= gift.ageMax else { continue }
            }

            let giftTags = Set(gift.tags.map { $0.lowercased() })

            // 4. Гендерный фильтр — жёсткий
            // Если товар помечен Female — не показываем мужчине (и наоборот)
            if recipient.gender == "Male" && giftTags.contains("female") { continue }
            if recipient.gender == "Female" && giftTags.contains("male") { continue }

            var explanation: [String] = []
            var score: Double = 0

            // ── A. Tag Score ──────────────────────────────────────────────────
            let directMatches   = giftTags.intersection(directUserTags)
            let expandedMatches = giftTags.intersection(expandedUserTags).subtracting(directUserTags)

            let tagScore: Double
            if expandedUserTags.isEmpty {
                tagScore = 0.25
            } else {
                let direct   = Double(directMatches.count) * 1.0
                let indirect = Double(expandedMatches.count) * 0.4
                tagScore = min((direct + indirect) / max(Double(recipient.tags.count), 1.0), 1.0)
            }
            score += tagScore * weightTags

            if !directMatches.isEmpty {
                explanation.append("Интересы: \(directMatches.filter { $0 != "female" && $0 != "male" }.sorted().joined(separator: ", "))")
            } else if !expandedMatches.isEmpty {
                explanation.append("Близко к интересам: \(expandedMatches.filter { $0 != "female" && $0 != "male" }.sorted().prefix(2).joined(separator: ", "))")
            }

            // Если теги заданы но совпадений 0 — пропускаем
            if !expandedUserTags.isEmpty && directMatches.isEmpty && expandedMatches.isEmpty { continue }

            // ── B. Budget Score ───────────────────────────────────────────────
            let budgetMid   = (budgetMin + budgetMax) / 2.0
            let budgetRange = max(budgetMax - budgetMin, 1.0)
            let budgetScore = max(0, 1.0 - abs(gift.price - budgetMid) / budgetRange)
            score += budgetScore * weightBudget
            explanation.append("Цена \(Int(gift.price)) ₽")

            // ── C. Gender Bonus ───────────────────────────────────────────────
            if !giftTags.intersection(genderBonus).isEmpty {
                score += weightGender
                explanation.append("Подходит по полу")
            }

            // ── D. Age Bonus ──────────────────────────────────────────────────
            if !giftTags.intersection(ageBonus).isEmpty {
                score += weightAge
            }

            // ── E. Occasion Bonus ─────────────────────────────────────────────
            if !giftTags.intersection(occasionBonus).isEmpty {
                score += weightOccasion
                if !occasion.isEmpty && occasion != "Просто так" {
                    explanation.append("Хорошо для: \(occasion)")
                }
            }

            scored.append((gift: gift, score: score, explanation: explanation))
        }

        // MARK: - Diversity Filter — макс 10 из категории, БЕЗ общего лимита
        let sortedAll = scored.sorted { $0.score > $1.score }
        var categoryCount: [String: Int] = [:]
        var diverse: [(gift: GiftItem, score: Double, explanation: [String])] = []

        for item in sortedAll {
            let cat   = item.gift.category
            let count = categoryCount[cat, default: 0]
            if count < 30 {
                diverse.append(item)
                categoryCount[cat] = count + 1
            }
        }

        return diverse.map { item in
            Recommendation(
                giftItem: item.gift,
                recipientID: recipient.id,
                score: item.score,
                explanation: item.explanation.joined(separator: " • ")
            )
        }
    }
}
