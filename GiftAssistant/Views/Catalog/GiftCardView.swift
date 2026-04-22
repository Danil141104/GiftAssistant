import SwiftUI

struct GiftCardView: View {
    let gift: GiftItem
    var explanation: String? = nil
    @EnvironmentObject var favoritesService: FavoritesService
    
    var body: some View {
        NavigationLink(destination: GiftDetailView(gift: gift).environmentObject(favoritesService)) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    GiftImageView(url: gift.imageURL)
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(12, corners: [.topLeft, .topRight])
                    
                    if favoritesService.isFavorite(gift) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .padding(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(gift.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(Color.theme.text)
                    
                    Text("\(Int(gift.price)) ₽")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.primary)
                    
                    if !gift.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(gift.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.theme.tag)
                                        .foregroundColor(Color.theme.secondary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    if let explanation = explanation {
                        Text(explanation)
                            .font(.caption2)
                            .foregroundColor(Color.theme.success)
                            .lineLimit(2)
                    }
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity)
            .background(Color.theme.card)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
