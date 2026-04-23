import SwiftUI

struct GiftDetailView: View {
    let gift: GiftItem
    @EnvironmentObject var favoritesService: FavoritesService
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    GiftImageView(url: gift.imageURL)
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            favoritesService.toggle(gift)
                        }
                    } label: {
                        Image(systemName: favoritesService.isFavorite(gift) ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(favoritesService.isFavorite(gift) ? .red : .white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(16)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(gift.category)
                        .font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.theme.primary.opacity(0.1))
                        .foregroundColor(Color.theme.primary).cornerRadius(8)
                    
                    Text(gift.name)
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(Color.theme.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(Int(gift.price)) ₽")
                        .font(.title).fontWeight(.bold)
                        .foregroundColor(Color.theme.primary)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(gift.tags, id: \.self) { tag in
                            Text(tag).font(.caption)
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.theme.tag)
                                .foregroundColor(Color.theme.secondary).cornerRadius(12)
                        }
                    }
                    
                    Rectangle().fill(Color.theme.tag).frame(height: 1)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Описание").font(.headline).foregroundColor(Color.theme.text)
                        Text(gift.description).font(.body)
                            .foregroundColor(Color.theme.textSecondary).lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(spacing: 12) {
                        InfoCard(icon: "person.2", title: "Возраст", value: "\(gift.ageMin)–\(gift.ageMax) лет")
                        InfoCard(icon: "tag", title: "Источник", value: gift.source == "local" ? "Каталог" : "API")
                    }
                    
                    Rectangle().fill(Color.theme.tag).frame(height: 1)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Купить").font(.headline).foregroundColor(Color.theme.text)
                        
                        ForEach(Shop.allCases, id: \.self) { shop in
                            if let url = URL(string: shop.searchURL(for: gift.name)) {
                                Link(destination: url) {
                                    HStack {
                                        Image(systemName: shop.icon).frame(width: 24)
                                        Text("Найти на \(shop.rawValue)").fontWeight(.medium)
                                        Spacer()
                                        Image(systemName: "arrow.up.right").font(.caption)
                                    }
                                    .padding(14)
                                    .background(shopColor(shop))
                                    .foregroundColor(.white).cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            favoritesService.toggle(gift)
                        }
                    } label: {
                        HStack {
                            Image(systemName: favoritesService.isFavorite(gift) ? "heart.fill" : "heart")
                            Text(favoritesService.isFavorite(gift) ? "В избранном" : "Добавить в избранное")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding(16)
                        .background(favoritesService.isFavorite(gift) ? Color.red.opacity(0.1) : Color.theme.tag)
                        .foregroundColor(favoritesService.isFavorite(gift) ? .red : Color.theme.primary)
                        .cornerRadius(14)
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func shopColor(_ shop: Shop) -> Color {
        switch shop {
        case .ozon: return Color(hex: "#005BFF")
        case .wildberries: return Color(hex: "#CB11AB")
        case .yandex: return Color(hex: "#FC3F1D")
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(Color.theme.primary)
            Text(title).font(.caption2).foregroundColor(Color.theme.textSecondary)
            Text(value).font(.caption).fontWeight(.semibold).foregroundColor(Color.theme.text)
        }
        .frame(maxWidth: .infinity).padding(12)
        .background(Color.theme.card).cornerRadius(12)
    }
}
