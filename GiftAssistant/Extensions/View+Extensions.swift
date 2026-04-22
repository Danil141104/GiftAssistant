import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color.theme.card)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
