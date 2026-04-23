import SwiftUI
import FirebaseFirestore

struct UserProfileData: Codable {
    var userID: String; var displayName: String; var email: String
    var gender: String; var age: Int; var birthday: Date?; var blacklist: [String]
    init(userID: String, email: String) {
        self.userID = userID
        self.displayName = email.components(separatedBy: "@").first ?? "Пользователь"
        self.email = email; self.gender = "Other"; self.age = 0; self.birthday = nil; self.blacklist = []
    }
}

struct UserProfileSetupView: View {
    let userID: String
    let isOnboarding: Bool
    var onDone: (() -> Void)?
    @State private var displayName = ""
    @State private var gender = "Other"
    @State private var birthday = Date()
    @State private var hasBirthday = false
    @State private var isSaving = false
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var age: Int {
        guard hasBirthday else { return 0 }
        return Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
    }
    var canSave: Bool { !displayName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill").font(.system(size: 70)).foregroundColor(Color.theme.primary)
                        Text(isOnboarding ? "Расскажите о себе" : "Редактировать профиль")
                            .font(.title2).fontWeight(.bold).foregroundColor(Color.theme.primary)
                        if isOnboarding {
                            Text("Эти данные помогут друзьям лучше подбирать вам подарки")
                                .font(.subheadline).foregroundColor(Color.theme.textSecondary).multilineTextAlignment(.center).padding(.horizontal)
                        }
                    }.padding(.top, 8)

                    if isLoading { ProgressView() }
                    else {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Имя").font(.headline)
                                TextField("Как вас зовут?", text: $displayName).textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Пол").font(.headline)
                                Picker("Пол", selection: $gender) {
                                    Text("Мужской").tag("Male"); Text("Женский").tag("Female"); Text("Другой").tag("Other")
                                }.pickerStyle(.segmented)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                HStack { Text("День рождения").font(.headline); Spacer(); Toggle("", isOn: $hasBirthday).labelsHidden() }
                                if hasBirthday {
                                    DatePicker("Дата рождения", selection: $birthday, in: ...Date(), displayedComponents: .date).datePickerStyle(.compact)
                                    Text("Возраст: \(age) лет").font(.caption).foregroundColor(Color.theme.textSecondary)
                                }
                            }.animation(.easeInOut(duration: 0.2), value: hasBirthday)

                            Button { Task { await saveProfile() } } label: {
                                HStack {
                                    if isSaving { ProgressView().tint(.white).padding(.trailing, 4) }
                                    Text(isSaving ? "Сохранение..." : "Сохранить").fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity).padding()
                                .background(canSave ? Color.theme.primary : Color.gray.opacity(0.3))
                                .foregroundColor(.white).cornerRadius(14)
                            }.disabled(!canSave || isSaving)

                            if isOnboarding {
                                Button("Пропустить") { onDone?(); dismiss() }
                                    .foregroundColor(Color.theme.textSecondary).font(.subheadline)
                            }
                        }.padding(.horizontal, 24)
                    }
                }.padding(.bottom, 32)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle(isOnboarding ? "Профиль" : "Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnboarding { ToolbarItem(placement: .navigationBarLeading) { Button("Отмена") { dismiss() } } }
            }
            .task { await loadProfile() }
        }
    }

    private func loadProfile() async {
        isLoading = true
        let doc = try? await Firestore.firestore().collection("userProfiles").document(userID).getDocument()
        if let data = doc?.data() {
            displayName = data["displayName"] as? String ?? ""
            gender = data["gender"] as? String ?? "Other"
            if let ts = data["birthday"] as? Timestamp { birthday = ts.dateValue(); hasBirthday = true }
        }
        isLoading = false
    }

    private func saveProfile() async {
        isSaving = true
        var data: [String: Any] = ["displayName": displayName.trimmingCharacters(in: .whitespaces), "gender": gender, "updatedAt": Date()]
        if hasBirthday { data["birthday"] = Timestamp(date: birthday); data["age"] = age }
        else { data["birthday"] = FieldValue.delete(); data["age"] = 0 }
        try? await Firestore.firestore().collection("userProfiles").document(userID).setData(data, merge: true)
        isSaving = false; onDone?(); dismiss()
    }
}
