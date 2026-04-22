import SwiftUI
import FirebaseFirestore
import Combine


// MARK: - Message Model

struct ChatMessage: Identifiable, Codable {
    var id: String = UUID().uuidString
    var userID: String
    var userName: String
    var text: String
    var createdAt: Date = Date()

    var isCurrentUser: Bool = false // вычисляется на стороне UI
}

// MARK: - GroupChatView

struct GroupChatView: View {
    let roomID: String
    let userID: String

    @StateObject private var vm = GroupChatViewModel()
    @State private var messageText = ""
    @FocusState private var inputFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(vm.messages) { message in
                                ChatBubble(
                                    message: message,
                                    isMe: message.userID == userID
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal).padding(.top, 8).padding(.bottom, 16)
                    }
                    .onChange(of: vm.messages.count) { _ in
                        if let last = vm.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onAppear {
                        if let last = vm.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }

                Divider()

                // Input
                HStack(spacing: 10) {
                    TextField("Message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .focused($inputFocused)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .foregroundColor(messageText.trimmingCharacters(in: .whitespaces).isEmpty
                                             ? Color.theme.textSecondary : Color.theme.primary)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal).padding(.vertical, 10)
                .background(Color.theme.card)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("Group Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { vm.startListening(roomID: roomID) }
            .onDisappear { vm.stopListening() }
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messageText = ""
        Task { await vm.sendMessage(roomID: roomID, userID: userID, text: text) }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage
    let isMe: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 60) }

            if !isMe {
                // Avatar
                Circle()
                    .fill(Color.theme.primary.opacity(0.15))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(message.userName.prefix(1).uppercased())
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(Color.theme.primary)
                    )
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                if !isMe {
                    Text(message.userName)
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundColor(Color.theme.textSecondary)
                }

                Text(message.text)
                    .font(.subheadline)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(isMe ? Color.theme.primary : Color.theme.card)
                    .foregroundColor(isMe ? .white : Color.theme.text)
                    .cornerRadius(16, corners: isMe
                        ? [.topLeft, .topRight, .bottomLeft]
                        : [.topLeft, .topRight, .bottomRight])

                Text(message.createdAt, style: .time)
                    .font(.caption2).foregroundColor(Color.theme.textSecondary)
            }

            if !isMe { Spacer(minLength: 60) }
        }
    }
}

// MARK: - GroupChatViewModel

@MainActor
class GroupChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var unreadCount: Int = 0

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening(roomID: String) {
        listener = db.collection("groupRooms")
            .document(roomID)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let docs = snap?.documents else { return }
                self.messages = docs.compactMap { doc -> ChatMessage? in
                    let d = doc.data()
                    guard let userID = d["userID"] as? String,
                          let userName = d["userName"] as? String,
                          let text = d["text"] as? String,
                          let ts = d["createdAt"] as? Timestamp else { return nil }
                    return ChatMessage(
                        id: doc.documentID,
                        userID: userID,
                        userName: userName,
                        text: text,
                        createdAt: ts.dateValue()
                    )
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func sendMessage(roomID: String, userID: String, text: String) async {
        // Получаем имя пользователя из профиля
        let userName = await fetchDisplayName(userID: userID)

        let msg = ChatMessage(
            userID: userID,
            userName: userName,
            text: text
        )

        try? await db.collection("groupRooms")
            .document(roomID)
            .collection("messages")
            .document(msg.id)
            .setData([
                "userID":    msg.userID,
                "userName":  msg.userName,
                "text":      msg.text,
                "createdAt": Timestamp(date: msg.createdAt)
            ])
    }

    private func fetchDisplayName(userID: String) async -> String {
        let doc = try? await db.collection("userProfiles").document(userID).getDocument()
        return doc?.data()?["displayName"] as? String ?? "User"
    }
}
