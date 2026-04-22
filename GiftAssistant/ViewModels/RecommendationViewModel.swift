import Foundation
import Combine

@MainActor
class RecommendationViewModel: ObservableObject {
    @Published var savedRecommendations: [Recommendation] = []
    
    func save(_ recommendation: Recommendation) {
        if !savedRecommendations.contains(where: { $0.id == recommendation.id }) {
            savedRecommendations.append(recommendation)
        }
    }
    
    func remove(_ recommendation: Recommendation) {
        savedRecommendations.removeAll { $0.id == recommendation.id }
    }
}
