import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    let authService: AuthService
    let userID: String
    @EnvironmentObject var favoritesService: FavoritesService
    @EnvironmentObject var blacklistService: BlacklistService
    @EnvironmentObject var interestsService: InterestsService
    @EnvironmentObject var friendshipService: FriendshipService
    @EnvironmentObject var recipientVM: RecipientViewModel
    @State private var showInterestsQuestionnaire = false
    @State private var showProfileEdit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill").font(.system(size: 60)).foregroundColor(Color.theme.primary)
                        Text(authService.currentUser?.email ?? "Пользователь").font(.headline)
                        Button { showProfileEdit = true } label: {
                            Label("Редактировать профиль", systemImage: "pencil").font(.caption).foregroundColor(Color.theme.secondary)
                        }
                        if !interestsService.selectedInterests.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill").font(.caption2)
                                Text("\(interestsService.selectedInterests.count) интересов").font(.caption).fontWeight(.medium)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.theme.primary.opacity(0.1)).foregroundColor(Color.theme.primary).cornerRadius(20)
                        }
                    }.padding(.top, 20)

                    VStack(spacing: 0) {
                        NavigationLink(destination: RecipientListView(userID: userID)) {
                            ProfileRow(icon: "person.2", title: "Мои получатели", count: nil)
                        }
                        Divider()
                        NavigationLink(destination: FavoritesListView().environmentObject(favoritesService)) {
                            ProfileRow(icon: "heart.fill", title: "Избранное", count: favoritesService.favorites.count)
                        }
                        Divider()
                        NavigationLink(destination: BlacklistView().environmentObject(blacklistService)) {
                            ProfileRow(icon: "hand.thumbsdown", title: "Не дарить", count: blacklistService.blacklist.count)
                        }
                        Divider()
                        NavigationLink(destination: EventsListView(userID: userID)) {
                            ProfileRow(icon: "calendar", title: "События", count: nil)
                        }
                        Divider()
                        Button { showInterestsQuestionnaire = true } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "star.fill").foregroundColor(Color.theme.primary).frame(width: 24)
                                Text("Мои интересы").foregroundColor(Color.theme.text)
                                Spacer()
                                if !interestsService.selectedInterests.isEmpty {
                                    Text("\(interestsService.selectedInterests.count)").font(.caption).fontWeight(.semibold)
                                        .padding(.horizontal, 8).padding(.vertical, 2)
                                        .background(Color.theme.primary).foregroundColor(.white).cornerRadius(10)
                                }
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(Color.theme.textSecondary)
                            }.padding(.vertical, 14)
                        }.buttonStyle(.plain)
                        Divider()
                        NavigationLink(destination: FriendsView(userID: userID).environmentObject(friendshipService).environmentObject(recipientVM)) {
                            ProfileRow(icon: "person.2.fill", title: "Друзья", count: friendshipService.friends.count > 0 ? friendshipService.friends.count : nil)
                        }
                    }.cardStyle()

                    Button { shareFavorites() } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Поделиться избранным").fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.theme.tag).foregroundColor(Color.theme.primary).cornerRadius(12)
                    }

                    HStack(spacing: 12) {
                        StatCard(icon: "heart.fill", value: "\(favoritesService.favorites.count)", label: "Избранное", color: .red)
                        StatCard(icon: "person.2.fill", value: "\(friendshipService.friends.count)", label: "Друзья", color: Color.theme.secondary)
                        StatCard(icon: "star.fill", value: "\(interestsService.selectedInterests.count)", label: "Интересов", color: Color.theme.primary)
                    }

                    Spacer(minLength: 40)

                    Button { authService.signOut() } label: {
                        Text("Выйти").fontWeight(.medium).frame(maxWidth: .infinity).padding()
                            .background(Color.red.opacity(0.1)).foregroundColor(.red).cornerRadius(12)
                    }
                }.padding(.horizontal)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("Профиль")
            .sheet(isPresented: $showInterestsQuestionnaire) { InterestsQuestionnaireView(userID: userID, service: interestsService) }
            .sheet(isPresented: $showProfileEdit) { UserProfileSetupView(userID: userID, isOnboarding: false) }
            .badge(friendshipService.incomingRequests.count)
        }
    }

    private func shareFavorites() {
        guard !favoritesService.favorites.isEmpty else { return }
        var text = "🎁 Мой список подарков:\n\n"
        for (index, gift) in favoritesService.favorites.enumerated() { text += "\(index + 1). \(gift.name) — \(Int(gift.price)) ₽\n" }
        text += "\nСоставлено в GiftAssistant"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first, let root = window.rootViewController { root.present(av, animated: true) }
    }
}

struct ProfileRow: View {
    let icon: String; let title: String; let count: Int?
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundColor(Color.theme.primary).frame(width: 24)
            Text(title).foregroundColor(Color.theme.text)
            Spacer()
            if let count = count, count > 0 {
                Text("\(count)").font(.caption).fontWeight(.semibold)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Color.theme.primary).foregroundColor(.white).cornerRadius(10)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundColor(Color.theme.textSecondary)
        }.padding(.vertical, 14)
    }
}

struct StatCard: View {
    let icon: String; let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text(value).font(.title3).fontWeight(.bold).foregroundColor(Color.theme.text)
            Text(label).font(.caption2).foregroundColor(Color.theme.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(12).background(Color.theme.card).cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct FavoritesListView: View {
    @EnvironmentObject var favoritesService: FavoritesService
    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    var body: some View {
        ScrollView {
            if favoritesService.favorites.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "heart.slash").font(.system(size: 44)).foregroundColor(Color.theme.textSecondary)
                    Text("Пока пусто").font(.title3).fontWeight(.semibold)
                    Text("Нажмите на сердечко на карточке подарка,\nчтобы добавить в избранное")
                        .font(.subheadline).foregroundColor(Color.theme.textSecondary).multilineTextAlignment(.center)
                }.padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(favoritesService.favorites) { gift in GiftCardView(gift: gift) }
                }.padding(.horizontal).padding(.top, 8)
            }
        }
        .background(Color.theme.background.ignoresSafeArea())
        .navigationTitle("Избранное")
    }
}
