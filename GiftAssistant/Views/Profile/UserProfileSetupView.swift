import SwiftUI
import FirebaseFirestore

// MARK: - UserProfileData

struct UserProfileData: Codable {
    var userID: String
    var displayName: String
    var email: String
    var gender: String
    var age: Int
    var birthday: Date?
    var blacklist: [String]
    
    init(userID: String, email: String) {
        self.userID = userID
        self.displayName = email.components(separatedBy: "@").first ?? "User"
        self.email = email
        self.gender = "Other"
        self.age = 0
        self.birthday = nil
        self.blacklist = []
    }
}

// MARK: - UserProfileSetupView

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
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 70)).foregroundColor(Color.theme.primary)

                        Text(isOnboarding ? "Tell us about yourself" : "Edit Profile")
                            .font(.title2).fontWeight(.bold).foregroundColor(Color.theme.primary)

                        if isOnboarding {
                            Text("This helps friends pick better gifts for you")
                                .font(.subheadline).foregroundColor(Color.theme.textSecondary)
                                .multilineTextAlignment(.center).padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)

                    if isLoading {
                        ProgressView()
                    } else {
                        VStack(spacing: 20) {

                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name").font(.headline)
                                TextField("What's your name?", text: $displayName)
                                    .textFieldStyle(.roundedBorder)
                            }

                            // Gender
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender").font(.headline)
                                Picker("Gender", selection: $gender) {
                                    Text("Male").tag("Male")
                                    Text("Female").tag("Female")
                                    Text("Other").tag("Other")
                                }
                                .pickerStyle(.segmented)
                            }

                            // Birthday
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Birthday").font(.headline)
                                    Spacer()
                                    Toggle("", isOn: $hasBirthday).labelsHidden()
                                }

                                if hasBirthday {
                                    DatePicker("Date of birth", selection: $birthday, in: ...Date(), displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                    Text("Age: \(age) y.o.")
                                        .font(.caption).foregroundColor(Color.theme.textSecondary)
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: hasBirthday)

                            // Save
                            Button {
                                Task { await saveProfile() }
                            } label: {
                                HStack {
                                    if isSaving { ProgressView().tint(.white).padding(.trailing, 4) }
                                    Text(isSaving ? "Saving..." : "Save").fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity).padding()
                                .background(canSave ? Color.theme.primary : Color.gray.opacity(0.3))
                                .foregroundColor(.white).cornerRadius(14)
                            }
                            .disabled(!canSave || isSaving)

                            if isOnboarding {
                                Button("Skip") { onDone?(); dismiss() }
                                    .foregroundColor(Color.theme.textSecondary).font(.subheadline)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle(isOnboarding ? "Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isOnboarding {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .task { await loadProfile() }
        }
    }

    private func loadProfile() async {
        isLoading = true
        let doc = try? await Firestore.firestore()
            .collection("userProfiles").document(userID).getDocument()

        if let data = doc?.data() {
            displayName = data["displayName"] as? String ?? ""
            gender = data["gender"] as? String ?? "Other"
            if let ts = data["birthday"] as? Timestamp {
                birthday = ts.dateValue()
                hasBirthday = true
            }
        }
        isLoading = false
    }

    private func saveProfile() async {
        isSaving = true
        var data: [String: Any] = [
            "displayName": displayName.trimmingCharacters(in: .whitespaces),
            "gender": gender,
            "updatedAt": Date()
        ]
        if hasBirthday {
            data["birthday"] = Timestamp(date: birthday)
            data["age"] = age
        } else {
            data["birthday"] = FieldValue.delete()
            data["age"] = 0
        }

        try? await Firestore.firestore()
            .collection("userProfiles").document(userID)
            .setData(data, merge: true)

        isSaving = false
        onDone?()
        dismiss()
    }
}
