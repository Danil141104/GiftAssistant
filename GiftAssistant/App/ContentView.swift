import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var favoritesService: FavoritesService
    @EnvironmentObject var blacklistService: BlacklistService
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if authService.isLoggedIn {
                if authService.isEmailVerified {
                    if !hasSeenOnboarding {
                        OnboardingView(userID: authService.currentUser?.uid ?? "") {
                            hasSeenOnboarding = true
                        }
                    } else {
                        MainTabView()
                            .environmentObject(authService)
                            .environmentObject(favoritesService)
                            .environmentObject(blacklistService)
                    }
                } else {
                    EmailVerificationView(authService: authService)
                }
            } else {
                LoginView(viewModel: AuthViewModel(authService: authService))
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var favoritesService: FavoritesService
    @EnvironmentObject var blacklistService: BlacklistService
    @StateObject private var recipientVM = RecipientViewModel()
    @StateObject private var wizardVM = WizardViewModel()
    @StateObject private var interestsService = InterestsService()
    @StateObject private var friendshipService = FriendshipService()

    var userID: String { authService.currentUser?.uid ?? "" }
    var userEmail: String { authService.currentUser?.email ?? "" }

    var body: some View {
        TabView {
            WizardTabView(wizardVM: wizardVM, recipientVM: recipientVM, userID: userID)
                .environmentObject(favoritesService)
                .environmentObject(blacklistService)
                .environmentObject(interestsService)
                .environmentObject(friendshipService)
                .tabItem { Image(systemName: "wand.and.stars"); Text("Wizard") }

            CatalogListView()
                .environmentObject(favoritesService)
                .environmentObject(blacklistService)
                .tabItem { Image(systemName: "gift"); Text("Catalog") }

            GroupRoomListView(userID: userID)
                .tabItem { Image(systemName: "person.3"); Text("Rooms") }

            ProfileView(authService: authService, userID: userID)
                .environmentObject(favoritesService)
                .environmentObject(blacklistService)
                .environmentObject(interestsService)
                .environmentObject(friendshipService)
                .environmentObject(recipientVM)
                .tabItem { Image(systemName: "person"); Text("Profile") }
        }
        .tint(Color.theme.primary)
        .onAppear {
            recipientVM.startListening(userID: userID)
            friendshipService.startListening(userID: userID)
            Task {
                await interestsService.loadInterests(userID: userID)
                await friendshipService.setupProfile(
                    userID: userID,
                    email: userEmail,
                    displayName: userEmail.components(separatedBy: "@").first ?? "User"
                )
            }
        }
        .onDisappear {
            friendshipService.stopListening()
        }
        .onChange(of: blacklistService.blacklist) { newList in
            Task { await friendshipService.syncBlacklist(userID: userID, blacklist: newList) }
        }
    }
}

struct WizardTabView: View {
    @ObservedObject var wizardVM: WizardViewModel
    @ObservedObject var recipientVM: RecipientViewModel
    let userID: String
    @EnvironmentObject var blacklistService: BlacklistService
    @EnvironmentObject var interestsService: InterestsService
    @EnvironmentObject var friendshipService: FriendshipService
    @EnvironmentObject var favoritesService: FavoritesService
    @State private var step = 0

    var body: some View {
        NavigationStack {
            VStack {
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i <= step ? Color.theme.primary : Color.theme.tag)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal)

                Group {
                    switch step {
                    case 0: WizardStepOccasion(viewModel: wizardVM)
                    case 1: WizardStepRecipient(viewModel: wizardVM, recipientVM: recipientVM, userID: userID)
                                .environmentObject(friendshipService)
                    case 2: WizardStepBudget(viewModel: wizardVM)
                    case 3: WizardStepTags(viewModel: wizardVM)
                    case 4: WizardResultsView(viewModel: wizardVM)
                                .environmentObject(blacklistService)
                                .environmentObject(favoritesService)
                    default: EmptyView()
                    }
                }

                if step < 4 {
                    HStack(spacing: 16) {
                        if step > 0 {
                            Button("Back") { step -= 1 }
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.theme.tag).foregroundColor(Color.theme.primary).cornerRadius(12)
                        }
                        Button(step == 3 ? "Find Gifts" : "Next") {
                            if step == 3 { applyProfileInterests() }
                            step += 1
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(canProceed ? Color.theme.primary : Color.gray.opacity(0.3))
                        .foregroundColor(.white).cornerRadius(12)
                        .disabled(!canProceed)
                    }
                    .padding(.horizontal).padding(.bottom)
                } else {
                    Button("Start Over") { wizardVM.reset(); step = 0 }
                        .padding().foregroundColor(Color.theme.secondary)
                }
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("Gift Wizard")
        }
    }

    var canProceed: Bool {
        switch step {
        case 0: return !wizardVM.selectedOccasion.isEmpty
        case 1: return wizardVM.selectedRecipient != nil
        case 2: return wizardVM.budgetMax > wizardVM.budgetMin
        default: return true
        }
    }

    private func applyProfileInterests() {
        let profileTags = interestsService.allSelectedTags
        guard !profileTags.isEmpty else { return }
        profileTags.forEach { wizardVM.selectedTags.insert($0) }
    }
}
