import SwiftUI

struct WizardResultsView: View {
    @ObservedObject var viewModel: WizardViewModel
    @EnvironmentObject var blacklistService: BlacklistService
    @EnvironmentObject var favoritesService: FavoritesService
    @State private var sortBy: SortOption = .relevance

    enum SortOption: String, CaseIterable {
        case relevance = "Most Relevant"
        case priceLow  = "Price: Low to High"
        case priceHigh = "Price: High to Low"
    }

    var sortedRecommendations: [Recommendation] {
        switch sortBy {
        case .relevance:  return viewModel.recommendations
        case .priceLow:   return viewModel.recommendations.sorted { $0.giftItem.price < $1.giftItem.price }
        case .priceHigh:  return viewModel.recommendations.sorted { $0.giftItem.price > $1.giftItem.price }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.5)
                    Text("Finding gifts...").foregroundColor(Color.theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.recommendations.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 44))
                        .foregroundColor(Color.theme.textSecondary)
                    Text("No gifts found")
                        .font(.title3).fontWeight(.semibold)
                    Text("Try expanding your budget\nor selecting different interests")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.top, 60)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recommendations")
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(Color.theme.primary)
                        Text("Found \(viewModel.recommendations.count) gifts")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    Spacer()
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button {
                                sortBy = option
                            } label: {
                                Text(option.rawValue)
                                    .font(.caption)
                                    .fontWeight(sortBy == option ? .semibold : .regular)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(sortBy == option ? Color.theme.primary : Color.theme.card)
                                    .foregroundColor(sortBy == option ? .white : Color.theme.text)
                                    .cornerRadius(16)
                            }
                        }
                    }
                }

                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(sortedRecommendations.enumerated()), id: \.element.id) { index, rec in
                            NavigationLink(destination: GiftDetailView(gift: rec.giftItem)
                                .environmentObject(favoritesService)) {
                                ResultCardView(recommendation: rec, rank: index + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .onAppear {
            viewModel.generateRecommendations(blacklist: blacklistService.blacklist)
        }
    }
}

struct ResultCardView: View {
    let recommendation: Recommendation
    let rank: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(rankColor).frame(width: 28, height: 28)
                Text("\(rank)").font(.caption).fontWeight(.bold).foregroundColor(.white)
            }
            .padding(.top, 8)

            GiftImageView(url: recommendation.giftItem.imageURL)
                .frame(width: 90, height: 90)
                .cornerRadius(10).clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.giftItem.name)
                    .font(.subheadline).fontWeight(.semibold).lineLimit(2)

                Text("\(Int(recommendation.giftItem.price)) ₽")
                    .font(.headline).foregroundColor(Color.theme.primary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(recommendation.giftItem.tags, id: \.self) { tag in
                            Text(tag).font(.caption2)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.theme.tag)
                                .foregroundColor(Color.theme.secondary)
                                .cornerRadius(6)
                        }
                    }
                }

                Text(recommendation.explanation)
                    .font(.caption).foregroundColor(Color.theme.success).lineLimit(2)

                HStack(spacing: 6) {
                    ForEach(Shop.allCases, id: \.self) { shop in
                        SmallShopButton(shop: shop, query: recommendation.giftItem.name)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(Color.theme.card)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "#FFD700")
        case 2: return Color(hex: "#C0C0C0")
        case 3: return Color(hex: "#CD7F32")
        default: return Color.theme.textSecondary
        }
    }
}

struct SmallShopButton: View {
    let shop: Shop
    let query: String

    var body: some View {
        if let url = URL(string: shop.searchURL(for: query)) {
            Link(destination: url) {
                Text(shop.rawValue).font(.caption2).fontWeight(.medium)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(backgroundColor).foregroundColor(.white).cornerRadius(6)
            }
        }
    }

    private var backgroundColor: Color {
        switch shop {
        case .ozon:         return Color(hex: "#005BFF")
        case .wildberries:  return Color(hex: "#CB11AB")
        case .yandex:       return Color(hex: "#FC3F1D")
        }
    }
}
