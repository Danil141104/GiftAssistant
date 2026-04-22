import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let accent = Color("AccentColor")
    let primary = Color(red: 0.1, green: 0.23, blue: 0.43)
    let secondary = Color(red: 0.17, green: 0.34, blue: 0.6)
    let background = Color(red: 0.95, green: 0.96, blue: 0.97)
    let card = Color.white
    let text = Color(red: 0.13, green: 0.13, blue: 0.13)
    let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)
    let success = Color(red: 0.2, green: 0.78, blue: 0.35)
    let tag = Color(red: 0.91, green: 0.94, blue: 1.0)
}
