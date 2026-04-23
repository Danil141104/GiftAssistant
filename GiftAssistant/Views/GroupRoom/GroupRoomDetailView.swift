import SwiftUI
import FirebaseFirestore

struct GroupRoomDetailView: View {
    let roomID: String
    let userID: String
    @StateObject private var viewModel = GroupRoomViewModel()
    @State private var contributionAmount = ""
    @State private var copiedCode = false
    @State private var showAddPoll = false
    @State private var newPollOption = ""
    @Environment(\.dismiss) private var dismiss
    @State private var showGoalReachedAlert = false
    @State private var userName: String = "Участник"
    @State private var showChat = false

    var body: some View {
        ScrollView {
            if let room = viewModel.currentRoom {
                VStack(alignment: .leading, spacing: 16) {

                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Подарок для")
                                    .font(.caption).foregroundColor(Color.theme.textSecondary)
                                Text(room.recipientName)
                                    .font(.title2).fontWeight(.bold)
                            }
                            Spacer()
                            StatusBadge(status: room.status)
                        }
                        HStack {
                            Label(room.occasion, systemImage: "gift")
                                .font(.subheadline).foregroundColor(Color.theme.secondary)
                            Spacer()
                            Text(room.createdAt, style: .date)
                                .font(.caption).foregroundColor(Color.theme.textSecondary)
                        }
                    }
                    .cardStyle()

                    VStack(spacing: 10) {
                        Text("Код приглашения")
                            .font(.caption).foregroundColor(Color.theme.textSecondary)
                        Text(room.inviteCode)
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.theme.primary).tracking(6)
                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = room.inviteCode
                                copiedCode = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedCode = false }
                            } label: {
                                HStack {
                                    Image(systemName: copiedCode ? "checkmark" : "doc.on.doc")
                                    Text(copiedCode ? "Скопировано!" : "Копировать")
                                }
                                .font(.caption).fontWeight(.medium)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color.theme.tag)
                                .foregroundColor(copiedCode ? Color.theme.success : Color.theme.primary)
                                .cornerRadius(8)
                            }
                            Button { shareRoom(room) } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Поделиться")
                                }
                                .font(.caption).fontWeight(.medium)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(Color.theme.primary).foregroundColor(.white).cornerRadius(8)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity).cardStyle()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Прогресс сбора").font(.headline)
                        ProgressBarView(current: room.currentTotal, goal: room.budgetGoal)
                        if room.currentTotal >= room.budgetGoal {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundColor(Color.theme.success)
                                Text("Цель достигнута!").fontWeight(.semibold).foregroundColor(Color.theme.success)
                            }.padding(.top, 4)
                        }
                    }.cardStyle()

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Голосование за подарок").font(.headline)
                            Spacer()
                            Button { showAddPoll.toggle() } label: {
                                Image(systemName: "plus.circle.fill").foregroundColor(Color.theme.primary)
                            }
                        }
                        if showAddPoll {
                            HStack {
                                TextField("Вариант подарка...", text: $newPollOption).textFieldStyle(.roundedBorder)
                                Button {
                                    guard !newPollOption.isEmpty else { return }
                                    viewModel.addPollOption(roomID: roomID, option: newPollOption)
                                    newPollOption = ""
                                    showAddPoll = false
                                } label: {
                                    Text("Добавить").font(.caption).fontWeight(.semibold)
                                        .padding(.horizontal, 12).padding(.vertical, 8)
                                        .background(Color.theme.primary).foregroundColor(.white).cornerRadius(8)
                                }
                            }
                        }
                        if viewModel.pollOptions.isEmpty {
                            Text("Предложите варианты подарков для голосования")
                                .font(.caption).foregroundColor(Color.theme.textSecondary)
                        } else {
                            let totalVotes = viewModel.pollOptions.reduce(0) { $0 + $1.votes }
                            ForEach(viewModel.pollOptions) { option in
                                PollOptionRow(
                                    option: option, totalVotes: totalVotes,
                                    hasVoted: option.voterIDs.contains(userID)
                                ) { viewModel.vote(roomID: roomID, optionID: option.id, userID: userID) }
                            }
                        }
                    }.cardStyle()

                    if room.status == "open" {
                        VStack(spacing: 12) {
                            Text("Внести взнос").font(.headline)
                            HStack(spacing: 10) {
                                ForEach([500, 1000, 2000], id: \.self) { amount in
                                    Button { contributionAmount = "\(amount)" } label: {
                                        Text("\(amount) ₽").font(.caption).fontWeight(.medium)
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(contributionAmount == "\(amount)" ? Color.theme.primary : Color.theme.tag)
                                            .foregroundColor(contributionAmount == "\(amount)" ? .white : Color.theme.primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            HStack {
                                TextField("Сумма ₽", text: $contributionAmount)
                                    .textFieldStyle(.roundedBorder).keyboardType(.numberPad)
                                Button {
                                    guard let amount = Double(contributionAmount), amount > 0 else { return }
                                    viewModel.addContribution(roomID: roomID, userID: userID, userName: userName, amount: amount)
                                    contributionAmount = ""
                                } label: {
                                    HStack {
                                        Image(systemName: "paperplane.fill")
                                        Text("Отправить")
                                    }
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                    .background(contributionAmount.isEmpty ? Color.gray.opacity(0.3) : Color.theme.success)
                                    .foregroundColor(.white).cornerRadius(10)
                                }
                                .disabled(contributionAmount.isEmpty)
                            }
                        }.cardStyle()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Участники").font(.headline)
                            Spacer()
                            Text("\(viewModel.contributions.count) взносов")
                                .font(.caption).foregroundColor(Color.theme.textSecondary)
                        }
                        if viewModel.contributions.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "tray").font(.title2).foregroundColor(Color.theme.textSecondary)
                                    Text("Взносов пока нет").font(.subheadline).foregroundColor(Color.theme.textSecondary)
                                }
                                Spacer()
                            }.padding(.vertical, 16)
                        } else {
                            ForEach(viewModel.contributions) { c in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color.theme.primary.opacity(0.1)).frame(width: 36, height: 36)
                                        Text(String(c.userName.prefix(1)).uppercased())
                                            .font(.subheadline).fontWeight(.bold).foregroundColor(Color.theme.primary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(c.userName).font(.subheadline).fontWeight(.medium)
                                        Text(c.createdAt, style: .relative).font(.caption2).foregroundColor(Color.theme.textSecondary)
                                    }
                                    Spacer()
                                    Text("+\(Int(c.amount)) ₽").font(.subheadline).fontWeight(.bold).foregroundColor(Color.theme.success)
                                }
                                .padding(.vertical, 4)
                                if c.id != viewModel.contributions.last?.id { Divider() }
                            }
                        }
                    }.cardStyle()

                    Button {
                        showChat = true
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                            Text("Групповой чат").fontWeight(.semibold)
                            Spacer()
                            if viewModel.unreadCount > 0 {
                                Text("\(viewModel.unreadCount)")
                                    .font(.caption).fontWeight(.bold)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color.red)
                                    .foregroundColor(.white).cornerRadius(10)
                            }
                            Image(systemName: "chevron.right").font(.caption)
                        }
                        .padding()
                        .background(Color.theme.card)
                        .cornerRadius(12)
                        .foregroundColor(Color.theme.primary)
                    }

                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("\(room.memberIDs.count) участников в комнате")
                    }
                    .font(.caption).foregroundColor(Color.theme.textSecondary).frame(maxWidth: .infinity)

                    if room.organizerID == userID {
                        Button {
                            Task { await deleteRoom(room) }
                        } label: {
                            Label("Удалить комнату", systemImage: "trash")
                                .font(.subheadline).foregroundColor(.red)
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.red.opacity(0.08)).cornerRadius(12)
                        }
                    } else {
                        Button {
                            Task { await leaveRoom(room) }
                        } label: {
                            Label("Покинуть комнату", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.subheadline).foregroundColor(.orange)
                                .frame(maxWidth: .infinity).padding()
                                .background(Color.orange.opacity(0.08)).cornerRadius(12)
                        }
                    }
                }
                .padding()
            } else {
                VStack(spacing: 12) {
                    ProgressView().scaleEffect(1.5)
                    Text("Загрузка комнаты...").foregroundColor(Color.theme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.top, 100)
            }
        }
        .background(Color.theme.background.ignoresSafeArea())
        .navigationTitle("Комната")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.listenToRoom(roomID: roomID)
            Task { await loadUserName() }
        }
        .onChange(of: viewModel.currentRoom?.currentTotal) { newTotal in
            guard let room = viewModel.currentRoom,
                  let total = newTotal,
                  total >= room.budgetGoal,
                  room.status == "open",
                  room.organizerID == userID else { return }
            Task {
                try? await Firestore.firestore()
                    .collection("groupRooms").document(roomID)
                    .updateData(["status": "closed"])
                showGoalReachedAlert = true
            }
        }
        .alert("🎉 Цель достигнута!", isPresented: $showGoalReachedAlert) {
            Button("OK") { }
        } message: {
            Text("Сбор завершён! Комната закрыта.")
        }
        .onDisappear { viewModel.stopListening() }
        .sheet(isPresented: $showChat) {
            GroupChatView(roomID: roomID, userID: userID)
        }
    }

    private func deleteRoom(_ room: GroupRoom) async {
        try? await Firestore.firestore()
            .collection("groupRooms").document(room.id).delete()
        dismiss()
    }

    private func leaveRoom(_ room: GroupRoom) async {
        var members = room.memberIDs
        members.removeAll { $0 == userID }
        try? await Firestore.firestore()
            .collection("groupRooms").document(room.id)
            .updateData(["memberIDs": members])
        dismiss()
    }

    private func loadUserName() async {
        let db = Firestore.firestore()
        let doc = try? await db.collection("userProfiles").document(userID).getDocument()
        if let name = doc?.data()?["displayName"] as? String, !name.isEmpty {
            userName = name
        }
    }

    private func shareRoom(_ room: GroupRoom) {
        let text = "Присоединяйся к сбору на подарок для \(room.recipientName)!\nПовод: \(room.occasion)\nКод комнаты: \(room.inviteCode)\nОсталось собрать: \(Int(room.budgetGoal - room.currentTotal)) ₽"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let root = window.rootViewController {
            root.present(av, animated: true)
        }
    }
}

struct PollOptionRow: View {
    let option: PollOption
    let totalVotes: Int
    let hasVoted: Bool
    let onVote: () -> Void

    var percentage: Double {
        totalVotes > 0 ? Double(option.votes) / Double(totalVotes) : 0
    }

    var body: some View {
        Button { onVote() } label: {
            HStack(spacing: 10) {
                Image(systemName: hasVoted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(hasVoted ? Color.theme.primary : Color.theme.textSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.name).font(.subheadline).fontWeight(.medium).foregroundColor(Color.theme.text)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.theme.tag).frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(hasVoted ? Color.theme.primary : Color.theme.secondary)
                                .frame(width: geo.size.width * percentage, height: 6)
                        }
                    }.frame(height: 6)
                }
                Text("\(option.votes)").font(.caption).fontWeight(.bold)
                    .foregroundColor(Color.theme.primary).frame(width: 30)
            }
            .padding(10)
            .background(hasVoted ? Color.theme.primary.opacity(0.05) : Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}
