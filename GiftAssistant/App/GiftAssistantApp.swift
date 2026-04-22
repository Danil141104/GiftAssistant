import SwiftUI
import Firebase

@main
struct GiftAssistantApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var favoritesService = FavoritesService()
    @StateObject private var blacklistService = BlacklistService()
    
    init() {
        FirebaseApp.configure()
        NotificationService.shared.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(favoritesService)
                .environmentObject(blacklistService)
        }
    }
}
