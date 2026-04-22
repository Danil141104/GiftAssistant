import SwiftUI

struct GiftImageView: View {
    let url: String?
    
    var body: some View {
        if let urlString = url, let imageURL = URL(string: urlString) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholder
                case .empty:
                    ProgressView()
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }
    
    var placeholder: some View {
        ZStack {
            Color.theme.tag
            Image(systemName: "gift.fill")
                .font(.title)
                .foregroundColor(Color.theme.secondary)
        }
    }
}
