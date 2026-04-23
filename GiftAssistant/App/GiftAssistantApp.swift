import SwiftUI
import Firebase

@main
struct GiftAssistantApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var favoritesService = FavoritesService()
    @StateObject private var blacklistService = BlacklistService()

    // Комната которую нужно открыть по диплинку
    @State private var pendingRoomCode: String? = nil

    init() {
        FirebaseApp.configure()
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(pendingRoomCode: $pendingRoomCode)
                .environmentObject(authService)
                .environmentObject(favoritesService)
                .environmentObject(blacklistService)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // giftassistant://room/ABCDEF
        guard url.scheme == "giftassistant",
              url.host == "room",
              let code = url.pathComponents.last, !code.isEmpty else { return }
        pendingRoomCode = code
    }
}
