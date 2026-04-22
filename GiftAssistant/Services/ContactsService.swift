import Foundation
import Contacts
import Combine

struct ContactCandidate: Identifiable {
    let id: String
    let name: String
    let birthday: Date?
    let age: Int?
    let phone: String?
    let imageData: Data?
    
    var ageString: String {
        guard let age else { return "Возраст неизвестен" }
        return "\(age) лет"
    }
    
    var birthdayString: String? {
        guard let birthday else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: birthday)
    }
}

class ContactsService: ObservableObject {
    @Published var candidates: [ContactCandidate] = []
    @Published var isLoading = false
    @Published var permissionDenied = false
    @Published var errorMessage: String?
    
    // MARK: - Permission
    
    func requestAccessAndLoad() async {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            if granted {
                await loadContacts(store: store)
            } else {
                await MainActor.run {
                    self.permissionDenied = true
                    self.errorMessage = "Доступ к контактам запрещён. Разрешите в Настройках."
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Ошибка доступа к контактам: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Load (enumerateContacts на фоновом потоке)
    
    private func loadContacts(store: CNContactStore) async {
        await MainActor.run { self.isLoading = true }
        
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        request.sortOrder = .givenName
        
        do {
            let results = try await Task.detached(priority: .userInitiated) {
                var contacts: [ContactCandidate] = []
                try store.enumerateContacts(with: request) { contact, _ in
                    let name = [contact.givenName, contact.familyName]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    guard !name.isEmpty else { return }
                    
                    let birthday = contact.birthday.flatMap { Calendar.current.date(from: $0) }
                    let age = birthday.map { ContactsService.calculateAge(from: $0) }
                    let phone = contact.phoneNumbers.first?.value.stringValue
                    
                    contacts.append(ContactCandidate(
                        id: contact.identifier,
                        name: name,
                        birthday: birthday,
                        age: age,
                        phone: phone,
                        imageData: contact.thumbnailImageData
                    ))
                }
                return contacts
            }.value
            
            await MainActor.run {
                self.candidates = results
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Не удалось загрузить контакты: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Map to Recipient
    
    func makeRecipient(from candidate: ContactCandidate, userID: String, relationship: String, gender: String) -> Recipient {
        Recipient(
            userID: userID,
            name: candidate.name,
            gender: gender,
            age: candidate.age ?? 0,
            relationship: relationship,
            birthday: candidate.birthday
        )
    }
    
    // MARK: - Helpers
    
    static func calculateAge(from birthday: Date) -> Int {
        Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
    }
}
