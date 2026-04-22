import SwiftUI
import FirebaseFirestore

struct FriendsView: View {
    let userID: String
    @EnvironmentObject var friendshipService: FriendshipService
    @State private var searchEmail = ""
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Friends (\(friendshipService.friends.count))").tag(0)
                    Text("Requests (\(friendshipService.incomingRequests.count))").tag(1)
                    Text("Search").tag(2)
                }
                .pickerStyle(.segmented).padding()

                switch selectedTab {
                case 0: friendsList
                case 1: requestsList
                default: searchView
                }
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var friendsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                if friendshipService.friends.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash").font(.system(size: 44)).foregroundColor(Color.theme.textSecondary)
                        Text("No friends yet").font(.title3).fontWeight(.semibold)
                        Text("Find friends by email in the Search tab")
                            .font(.subheadline).foregroundColor(Color.theme.textSecondary).multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(friendshipService.friends) { friend in
                        NavigationLink(destination: FriendProfileView(friend: friend, currentUserID: userID)
                            .environmentObject(friendshipService)) {
                            FriendRow(profile: friend) {
                                Task { await friendshipService.removeFriend(friendID: friend.id, currentUserID: userID) }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
    }

    var requestsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !friendshipService.incomingRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Incoming Requests").font(.headline).padding(.horizontal)
                        ForEach(friendshipService.incomingRequests) { profile in
                            HStack(spacing: 12) {
                                AvatarCircle(name: profile.displayName, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.displayName).fontWeight(.semibold)
                                    Text(profile.email).font(.caption).foregroundColor(Color.theme.textSecondary)
                                }
                                Spacer()
                                HStack(spacing: 8) {
                                    Button {
                                        Task { await friendshipService.acceptRequest(fromUserID: profile.id, currentUserID: userID) }
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill").font(.title2).foregroundColor(Color.theme.success)
                                    }
                                    Button {
                                        Task { await friendshipService.declineRequest(fromUserID: profile.id, currentUserID: userID) }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(Color.theme.textSecondary)
                                    }
                                }
                            }
                            .padding().background(Color.theme.card).cornerRadius(12).padding(.horizontal)
                        }
                    }
                }

                if !friendshipService.outgoingRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sent Requests").font(.headline).padding(.horizontal)
                        ForEach(friendshipService.outgoingRequests) { profile in
                            HStack(spacing: 12) {
                                AvatarCircle(name: profile.displayName, size: 44)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.displayName).fontWeight(.semibold)
                                    Text(profile.email).font(.caption).foregroundColor(Color.theme.textSecondary)
                                }
                                Spacer()
                                Text("Pending").font(.caption)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.15)).foregroundColor(.orange).cornerRadius(10)
                            }
                            .padding().background(Color.theme.card).cornerRadius(12).padding(.horizontal)
                        }
                    }
                }

                if friendshipService.incomingRequests.isEmpty && friendshipService.outgoingRequests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray").font(.system(size: 44)).foregroundColor(Color.theme.textSecondary)
                        Text("No requests").font(.title3).fontWeight(.semibold)
                    }
                    .padding(.top, 60)
                }
            }
            .padding(.vertical)
        }
    }

    var searchView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(Color.theme.textSecondary)
                TextField("Enter user email", text: $searchEmail)
                    .keyboardType(.emailAddress).autocapitalization(.none)
                if !searchEmail.isEmpty {
                    Button { searchEmail = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Color.theme.textSecondary)
                    }
                }
            }
            .padding(12).background(Color.theme.card).cornerRadius(12).padding(.horizontal)

            Button {
                Task { await friendshipService.searchUser(email: searchEmail, currentUserID: userID) }
            } label: {
                Text("Search").fontWeight(.semibold)
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(searchEmail.isEmpty ? Color.gray.opacity(0.3) : Color.theme.primary)
                    .foregroundColor(.white).cornerRadius(12)
            }
            .disabled(searchEmail.isEmpty).padding(.horizontal)

            if friendshipService.isLoading { ProgressView() }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(friendshipService.searchResults) { profile in
                        let status = friendshipService.relationStatus(with: profile.id, currentUserID: userID)
                        HStack(spacing: 12) {
                            AvatarCircle(name: profile.displayName, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.displayName).fontWeight(.semibold)
                                Text(profile.email).font(.caption).foregroundColor(Color.theme.textSecondary)
                            }
                            Spacer()
                            switch status {
                            case "friends":
                                Label("Friend", systemImage: "checkmark").font(.caption).foregroundColor(Color.theme.success)
                            case "pending_sent":
                                Text("Request sent").font(.caption)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.15)).foregroundColor(.orange).cornerRadius(8)
                            case "pending_received":
                                Button {
                                    Task { await friendshipService.acceptRequest(fromUserID: profile.id, currentUserID: userID) }
                                } label: {
                                    Text("Accept").font(.caption).fontWeight(.semibold)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color.theme.success).foregroundColor(.white).cornerRadius(8)
                                }
                            default:
                                Button {
                                    Task { await friendshipService.sendRequest(fromUserID: userID, toUser: profile) }
                                } label: {
                                    Label("Add", systemImage: "person.badge.plus")
                                        .font(.caption).fontWeight(.semibold)
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color.theme.primary).foregroundColor(.white).cornerRadius(8)
                                }
                            }
                        }
                        .padding().background(Color.theme.card).cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let profile: UserProfile
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarCircle(name: profile.displayName, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.displayName).fontWeight(.semibold)
                HStack(spacing: 6) {
                    if profile.age > 0 {
                        Text("\(profile.age) y.o.").font(.caption).foregroundColor(Color.theme.textSecondary)
                    }
                    if profile.gender != "Other" {
                        Text("•").font(.caption).foregroundColor(Color.theme.textSecondary)
                        Text(profile.genderString).font(.caption).foregroundColor(Color.theme.textSecondary)
                    }
                    if let bd = profile.birthdayString {
                        Text("•").font(.caption).foregroundColor(Color.theme.textSecondary)
                        Label(bd, systemImage: "gift.fill").font(.caption).foregroundColor(Color.theme.secondary)
                    }
                }
                if !profile.blacklist.isEmpty {
                    Text("🚫 Do not gift: \(profile.blacklist.prefix(3).joined(separator: ", "))")
                        .font(.caption2).foregroundColor(Color.theme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(Color.theme.textSecondary)
        }
        .padding().background(Color.theme.card).cornerRadius(12)
    }
}

// MARK: - Avatar Circle

struct AvatarCircle: View {
    let name: String
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color.theme.primary.opacity(0.15))
            .frame(width: size, height: size)
            .overlay(
                Text(name.prefix(1).uppercased())
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundColor(Color.theme.primary)
            )
    }
}

// MARK: - Friend Profile View

struct FriendProfileView: View {
    let friend: UserProfile
    let currentUserID: String
    @EnvironmentObject var friendshipService: FriendshipService
    @EnvironmentObject var recipientVM: RecipientViewModel

    @State private var friendInterests: [String] = []
    @State private var isLoadingInterests = true
    @State private var showAddedBanner = false
    @State private var alreadyAdded = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                VStack(spacing: 10) {
                    AvatarCircle(name: friend.displayName, size: 80)
                    Text(friend.displayName).font(.title2).fontWeight(.bold)
                    Text(friend.email).font(.subheadline).foregroundColor(Color.theme.textSecondary)
                }
                .padding(.top, 8)

                Button { addAsRecipient() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: alreadyAdded ? "checkmark.circle.fill" : "person.badge.plus")
                        Text(alreadyAdded ? "Already in recipients" : "Add as Recipient")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity).padding()
                    .background(alreadyAdded ? Color.theme.success : Color.theme.primary)
                    .foregroundColor(.white).cornerRadius(14)
                }
                .disabled(alreadyAdded).padding(.horizontal)

                if showAddedBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Color.theme.success)
                        Text("Added to recipients!").font(.subheadline).foregroundColor(Color.theme.success)
                    }
                    .padding().frame(maxWidth: .infinity)
                    .background(Color.theme.success.opacity(0.1)).cornerRadius(10)
                    .padding(.horizontal).transition(.opacity)
                }

                // Do Not Gift
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsdown.fill").foregroundColor(.orange)
                        Text("Do Not Gift").font(.headline)
                    }
                    if friend.blacklist.isEmpty {
                        Text("List is empty — anything goes!")
                            .font(.subheadline).foregroundColor(Color.theme.textSecondary)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(friend.blacklist, id: \.self) { item in
                                HStack(spacing: 4) {
                                    Image(systemName: "xmark").font(.caption2)
                                    Text(item).font(.caption).fontWeight(.medium)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1)).foregroundColor(.orange).cornerRadius(20)
                            }
                        }
                    }
                }
                .padding().background(Color.theme.card).cornerRadius(14).padding(.horizontal)

                // Interests
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill").foregroundColor(Color.theme.primary)
                        Text("Interests").font(.headline)
                    }
                    if isLoadingInterests {
                        ProgressView().frame(maxWidth: .infinity)
                    } else if friendInterests.isEmpty {
                        Text("No interests listed").font(.subheadline).foregroundColor(Color.theme.textSecondary)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(friendInterests, id: \.self) { interest in
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill").font(.caption2)
                                    Text(interest).font(.caption).fontWeight(.medium)
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(Color.theme.primary.opacity(0.1)).foregroundColor(Color.theme.primary).cornerRadius(20)
                            }
                        }
                    }
                }
                .padding().background(Color.theme.card).cornerRadius(14).padding(.horizontal)

                Button {
                    Task { await friendshipService.removeFriend(friendID: friend.id, currentUserID: currentUserID) }
                } label: {
                    Text("Remove Friend").font(.subheadline).foregroundColor(.red)
                }
                .padding(.bottom, 24)
            }
        }
        .background(Color.theme.background.ignoresSafeArea())
        .navigationTitle(friend.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadFriendInterests(); checkIfAlreadyAdded() }
        .animation(.easeInOut, value: showAddedBanner)
    }

    private func loadFriendInterests() async {
        isLoadingInterests = true
        if let data = try? await Firestore.firestore()
            .collection("userInterests").document(friend.id).getDocument().data(),
           let tags = data["tags"] as? [String] {
            friendInterests = tags.sorted()
        }
        isLoadingInterests = false
    }

    private func addAsRecipient() {
        let recipient = Recipient(userID: currentUserID, name: friend.displayName,
                                  gender: friend.gender, age: friend.age,
                                  relationship: "Friend", birthday: friend.birthday)
        recipientVM.addRecipient(recipient)
        alreadyAdded = true
        withAnimation { showAddedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { showAddedBanner = false } }
    }

    private func checkIfAlreadyAdded() {
        alreadyAdded = recipientVM.recipients.contains { $0.name == friend.displayName }
    }
}
