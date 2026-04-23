import SwiftUI

struct WizardStepRecipient: View {
    @ObservedObject var viewModel: WizardViewModel
    @ObservedObject var recipientVM: RecipientViewModel
    @EnvironmentObject var friendshipService: FriendshipService
    @StateObject private var voiceService = VoiceInputService()
    let userID: String
    @State private var showAddNew = false
    @State private var newName = ""
    @State private var newGender = "Male"
    @State private var newAge = ""
    @State private var newRelationship = ""
    @State private var showVoiceAppliedBanner = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Кому дарим?").font(.title2).fontWeight(.bold).foregroundColor(Color.theme.primary)
                HStack { Spacer(); VoiceInputButton(voiceService: voiceService) { result in handleVoiceResult(result) }; Spacer() }

                if showVoiceAppliedBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(Color.theme.success)
                        Text("Данные голосового ввода применены!").font(.subheadline).foregroundColor(Color.theme.success)
                    }
                    .padding().frame(maxWidth: .infinity).background(Color.theme.success.opacity(0.1)).cornerRadius(10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !friendshipService.friends.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill").font(.caption).foregroundColor(Color.theme.primary)
                            Text("Друзья").font(.subheadline).fontWeight(.semibold).foregroundColor(Color.theme.primary)
                        }
                        ForEach(friendshipService.friends) { friend in
                            let isSelected = viewModel.selectedFriendID == friend.id
                            Button { selectFriend(friend) } label: {
                                HStack(spacing: 12) {
                                    AvatarCircle(name: friend.displayName, size: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(friend.displayName).fontWeight(.semibold).foregroundColor(Color.theme.text)
                                        HStack(spacing: 4) {
                                            if friend.age > 0 { Text("\(friend.age) лет").font(.caption).foregroundColor(Color.theme.textSecondary) }
                                            if friend.gender != "Other" {
                                                Text("•").font(.caption).foregroundColor(Color.theme.textSecondary)
                                                Text(friend.genderString).font(.caption).foregroundColor(Color.theme.textSecondary)
                                            }
                                        }
                                        if !friend.blacklist.isEmpty {
                                            Text("🚫 Не дарить: \(friend.blacklist.prefix(2).joined(separator: ", "))")
                                                .font(.caption2).foregroundColor(Color.theme.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(Color.theme.success) }
                                }
                                .padding()
                                .background(isSelected ? Color.theme.tag : Color.theme.card).cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.theme.primary : Color.clear, lineWidth: 2))
                            }.buttonStyle(.plain)
                        }
                    }
                    Divider()
                }

                if !recipientVM.recipients.isEmpty || showAddNew {
                    Text("Мои получатели").font(.subheadline).fontWeight(.semibold).foregroundColor(Color.theme.primary)
                }
                if recipientVM.recipients.isEmpty && !showAddNew && friendshipService.friends.isEmpty {
                    Text("Получателей пока нет. Добавьте или используйте голосовой ввод.")
                        .font(.subheadline).foregroundColor(Color.theme.textSecondary).multilineTextAlignment(.center).padding(.vertical, 8)
                }

                ForEach(recipientVM.recipients) { recipient in
                    Button {
                        viewModel.selectedRecipient = recipient; viewModel.selectedFriendID = nil; viewModel.friendBlacklist = []
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipient.name).fontWeight(.semibold).foregroundColor(Color.theme.text)
                                Text("\(recipient.relationship) • \(recipient.age) лет").font(.caption).foregroundColor(Color.theme.textSecondary)
                            }
                            Spacer()
                            if viewModel.selectedRecipient?.id == recipient.id && viewModel.selectedFriendID == nil {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(Color.theme.success)
                            }
                        }
                        .padding()
                        .background(viewModel.selectedRecipient?.id == recipient.id && viewModel.selectedFriendID == nil ? Color.theme.tag : Color.theme.card)
                        .cornerRadius(12)
                    }.buttonStyle(.plain)
                }

                if showAddNew {
                    VStack(spacing: 12) {
                        TextField("Имя", text: $newName).textFieldStyle(.roundedBorder)
                        Picker("Пол", selection: $newGender) {
                            Text("Мужской").tag("Male"); Text("Женский").tag("Female"); Text("Другой").tag("Other")
                        }.pickerStyle(.segmented)
                        TextField("Возраст", text: $newAge).textFieldStyle(.roundedBorder).keyboardType(.numberPad)
                        TextField("Кем приходится (друг, мама, коллега...)", text: $newRelationship).textFieldStyle(.roundedBorder)
                        Button("Сохранить получателя") {
                            guard let age = Int(newAge), !newName.isEmpty else { return }
                            let recipient = Recipient(userID: userID, name: newName, gender: newGender, age: age, relationship: newRelationship)
                            recipientVM.addRecipient(recipient); viewModel.selectedRecipient = recipient; viewModel.selectedFriendID = nil
                            showAddNew = false; newName = ""; newAge = ""; newRelationship = ""
                        }
                        .padding().frame(maxWidth: .infinity).background(Color.theme.primary).foregroundColor(.white).cornerRadius(12)
                    }.cardStyle()
                }

                Button { showAddNew.toggle() } label: {
                    Label(showAddNew ? "Отмена" : "Добавить получателя вручную", systemImage: showAddNew ? "xmark" : "plus")
                }.foregroundColor(Color.theme.secondary)

                Spacer(minLength: 40)
            }.padding()
        }
        .animation(.easeInOut(duration: 0.3), value: showVoiceAppliedBanner)
        .animation(.easeInOut(duration: 0.2), value: showAddNew)
    }

    private func selectFriend(_ friend: UserProfile) {
        let recipient = Recipient(userID: userID, name: friend.displayName, gender: friend.gender, age: friend.age, relationship: "Друг", birthday: friend.birthday)
        viewModel.selectedRecipient = recipient
        viewModel.selectFriendWithInterests(friend.id)
        viewModel.friendBlacklist = friend.blacklist
    }

    private func handleVoiceResult(_ result: VoiceInputResult) {
        let newRecipient = viewModel.applyVoiceInput(result, userID: userID)
        viewModel.selectedFriendID = nil
        if let recipient = newRecipient, recipient.name != "Без имени" {
            let exists = recipientVM.recipients.contains { $0.name == recipient.name }
            if !exists { recipientVM.addRecipient(recipient) }
            else if let existing = recipientVM.recipients.first(where: { $0.name == recipient.name }) { viewModel.selectedRecipient = existing }
        }
        withAnimation { showVoiceAppliedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { showVoiceAppliedBanner = false } }
    }
}
