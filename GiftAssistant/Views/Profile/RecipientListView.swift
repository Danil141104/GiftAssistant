import SwiftUI
import Contacts

struct RecipientListView: View {
    let userID: String
    @StateObject private var viewModel = RecipientViewModel()
    @StateObject private var contactsService = ContactsService()
    @State private var showContactsPicker = false

    var body: some View {
        List {
            ForEach(viewModel.recipients) { recipient in
                RecipientRow(recipient: recipient) {
                    viewModel.deleteRecipient(recipient)
                }
                .padding(.vertical, 4)
            }
            .onDelete { indexSet in
                for index in indexSet { viewModel.deleteRecipient(viewModel.recipients[index]) }
            }
        }
        .navigationTitle("Recipients")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showContactsPicker = true } label: {
                    Label("Import", systemImage: "person.crop.circle.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showContactsPicker) {
            ContactsPickerSheet(contactsService: contactsService, userID: userID) { candidate, relationship, gender in
                viewModel.importFromContact(candidate, userID: userID, relationship: relationship,
                                            gender: gender, contactsService: contactsService)
                showContactsPicker = false
            }
        }
        .onAppear { viewModel.startListening(userID: userID) }
        .onDisappear { viewModel.stopListening() }
        .overlay {
            if viewModel.recipients.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.slash").font(.system(size: 44)).foregroundColor(Color.theme.textSecondary)
                    Text("No recipients").font(.title3).fontWeight(.semibold)
                    Text("Add recipients manually\nor import from contacts")
                        .font(.subheadline).foregroundColor(Color.theme.textSecondary).multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Recipient Row

struct RecipientRow: View {
    let recipient: Recipient
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.theme.primary.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(recipient.name.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.theme.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recipient.name).fontWeight(.semibold)
                    Spacer()
                    if let bd = recipient.birthdayDisplayString {
                        Label(bd, systemImage: "gift.fill").font(.caption).foregroundColor(Color.theme.secondary)
                    }
                }
                HStack(spacing: 4) {
                    if !recipient.relationship.isEmpty { Text(recipient.relationship) }
                    if recipient.age > 0 { Text("•"); Text("\(recipient.age) y.o.") }
                    Text("•")
                    Text(recipient.gender == "Male" ? "M" : recipient.gender == "Female" ? "F" : "—")
                }
                .font(.caption).foregroundColor(Color.theme.textSecondary)

                if !recipient.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(recipient.tags, id: \.self) { tag in
                                Text(tag).font(.caption2)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.theme.tag).cornerRadius(6)
                            }
                        }
                    }
                }
            }

            if let onDelete {
                Button { onDelete() } label: {
                    Image(systemName: "trash").font(.caption).foregroundColor(Color.theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Contacts Picker Sheet

struct ContactsPickerSheet: View {
    @ObservedObject var contactsService: ContactsService
    let userID: String
    var onSelect: (ContactCandidate, String, String) -> Void

    @State private var searchText = ""
    @State private var selectedCandidate: ContactCandidate?
    @State private var relationship = ""
    @State private var gender = "Male"
    @State private var showConfirm = false
    @Environment(\.dismiss) private var dismiss

    var filtered: [ContactCandidate] {
        if searchText.isEmpty { return contactsService.candidates }
        return contactsService.candidates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            Group {
                if contactsService.permissionDenied {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.xmark").font(.system(size: 60)).foregroundColor(Color.theme.textSecondary)
                        Text("No Access to Contacts").font(.headline)
                        Text("Allow access in Settings → Privacy → Contacts")
                            .font(.subheadline).foregroundColor(Color.theme.textSecondary).multilineTextAlignment(.center).padding(.horizontal)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                        .padding().background(Color.theme.primary).foregroundColor(.white).cornerRadius(12)
                    }
                    .padding()
                } else if contactsService.isLoading {
                    ProgressView("Loading contacts…")
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(Color.theme.textSecondary)
                            TextField("Search by name", text: $searchText)
                        }
                        .padding(10).background(Color.theme.card).cornerRadius(10)
                        .padding(.horizontal).padding(.vertical, 8)

                        List(filtered) { candidate in
                            Button { selectedCandidate = candidate; showConfirm = true } label: {
                                ContactRow(candidate: candidate)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Choose Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
            }
            .sheet(isPresented: $showConfirm) {
                if let candidate = selectedCandidate {
                    ContactConfirmSheet(candidate: candidate, relationship: $relationship, gender: $gender) {
                        onSelect(candidate, relationship, gender)
                    }
                }
            }
        }
        .task {
            if contactsService.candidates.isEmpty { await contactsService.requestAccessAndLoad() }
        }
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let candidate: ContactCandidate

    var body: some View {
        HStack(spacing: 12) {
            if let data = candidate.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 44, height: 44).clipShape(Circle())
            } else {
                Circle().fill(Color.theme.tag).frame(width: 44, height: 44)
                    .overlay(Text(candidate.name.prefix(1)).font(.headline).foregroundColor(Color.theme.primary))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.name).fontWeight(.medium)
                HStack(spacing: 6) {
                    if let bd = candidate.birthdayString {
                        Label(bd, systemImage: "gift.fill").font(.caption).foregroundColor(Color.theme.secondary)
                    }
                    if let age = candidate.age {
                        Text("• \(age) y.o.").font(.caption).foregroundColor(Color.theme.textSecondary)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(Color.theme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Contact Confirm Sheet

struct ContactConfirmSheet: View {
    let candidate: ContactCandidate
    @Binding var relationship: String
    @Binding var gender: String
    var onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    let relationships = ["Friend", "Girlfriend", "Mom", "Dad", "Brother", "Sister",
                         "Husband", "Wife", "Colleague", "Boss", "Grandmother", "Grandfather", "Other"]

    var body: some View {
        NavigationView {
            Form {
                Section("Contact") {
                    HStack {
                        if let data = candidate.imageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 50, height: 50).clipShape(Circle())
                        } else {
                            Circle().fill(Color.theme.tag).frame(width: 50, height: 50)
                                .overlay(Text(candidate.name.prefix(1)).font(.title3).foregroundColor(Color.theme.primary))
                        }
                        VStack(alignment: .leading) {
                            Text(candidate.name).fontWeight(.semibold)
                            if let bd = candidate.birthdayString {
                                Text("Birthday: \(bd)").font(.caption).foregroundColor(Color.theme.textSecondary)
                            }
                            Text(candidate.ageString).font(.caption).foregroundColor(Color.theme.textSecondary)
                        }
                    }
                }
                Section("Relationship") {
                    Picker("Relationship", selection: $relationship) {
                        ForEach(relationships, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.wheel).frame(height: 120)
                }
                Section("Gender") {
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }.pickerStyle(.segmented)
                }
                Section {
                    Button { onConfirm(); dismiss() } label: {
                        HStack {
                            Spacer()
                            Text("Add Recipient").fontWeight(.semibold).foregroundColor(.white)
                            Spacer()
                        }.padding(.vertical, 4)
                    }
                    .listRowBackground(Color.theme.primary)
                }
            }
            .navigationTitle("Add from Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Back") { dismiss() } }
            }
            .onAppear { if relationship.isEmpty { relationship = relationships[0] } }
        }
    }
}
