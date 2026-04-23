import SwiftUI
import FirebaseFirestore

struct EventsListView: View {
    let userID: String
    @State private var events: [GiftEvent] = []
    @State private var showAdd = false
    @State private var listener: ListenerRegistration?
    private let firebase = FirebaseService()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Button { showAdd = true } label: {
                    Label("Добавить событие", systemImage: "plus")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.theme.primary).foregroundColor(.white).cornerRadius(12)
                }
                if events.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus").font(.system(size: 44)).foregroundColor(Color.theme.textSecondary)
                        Text("Нет событий").font(.title3).fontWeight(.semibold)
                        Text("Добавьте дни рождения и праздники,\nчтобы не забыть про подарок")
                            .font(.subheadline).foregroundColor(Color.theme.textSecondary).multilineTextAlignment(.center)
                    }.padding(.top, 40)
                } else {
                    ForEach(sortedEvents) { event in EventCardView(event: event) { deleteEvent(event) } }
                }
            }
            .padding(.horizontal).padding(.top, 8)
        }
        .background(Color.theme.background.ignoresSafeArea())
        .navigationTitle("События")
        .sheet(isPresented: $showAdd) { AddEventView(userID: userID) }
        .onAppear { startListening() }
        .onDisappear { listener?.remove() }
    }

    var sortedEvents: [GiftEvent] { events.sorted { $0.date < $1.date } }

    private func startListening() {
        listener = firebase.listenToCollection(collection: "events", whereField: "userID", isEqualTo: userID) { (items: [GiftEvent]) in
            self.events = items
        }
    }

    private func deleteEvent(_ event: GiftEvent) {
        NotificationService.shared.cancelNotification(identifier: event.id)
        Task { try? await firebase.deleteDocument(collection: "events", documentID: event.id) }
    }
}

struct EventCardView: View {
    let event: GiftEvent
    let onDelete: () -> Void

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: event.date).day ?? 0
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text("\(max(daysUntil, 0))").font(.title2).fontWeight(.bold)
                    .foregroundColor(daysUntil <= 3 ? .red : Color.theme.primary)
                Text("дней").font(.caption2).foregroundColor(Color.theme.textSecondary)
            }.frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(event.recipientName).fontWeight(.semibold)
                    if event.contactID != nil {
                        Image(systemName: "person.crop.circle.fill").font(.caption).foregroundColor(Color.theme.secondary)
                    }
                }
                HStack(spacing: 4) {
                    Image(systemName: occasionIcon(event.occasion)).font(.caption2).foregroundColor(Color.theme.secondary)
                    Text(event.occasion).font(.caption).foregroundColor(Color.theme.textSecondary)
                }
                Text(event.date, style: .date).font(.caption).foregroundColor(Color.theme.secondary)
                if daysUntil <= 0 {
                    Text("Сегодня или прошло!").font(.caption2).fontWeight(.semibold).foregroundColor(.red)
                } else if daysUntil <= 3 {
                    Text("Скоро!").font(.caption2).fontWeight(.semibold).foregroundColor(.orange)
                }
            }
            Spacer()
            Button { onDelete() } label: {
                Image(systemName: "trash").font(.caption).foregroundColor(Color.theme.textSecondary)
            }
        }
        .padding(14).background(Color.theme.card).cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    func occasionIcon(_ occasion: String) -> String {
        switch occasion {
        case "День рождения": return "birthday.cake"
        case "Новый год":     return "snowflake"
        case "Свадьба":       return "heart.circle"
        case "Годовщина":     return "heart.fill"
        case "Выпускной":     return "graduationcap"
        case "8 Марта":       return "staroflife.fill"
        case "23 Февраля":    return "star.fill"
        case "День матери":   return "figure.and.child.holdinghands"
        case "День отца":     return "figure.stand"
        case "Крестины":      return "drop.fill"
        case "Юбилей":        return "star.circle.fill"
        case "Корпоратив":    return "building.2"
        case "Новоселье":     return "house.fill"
        case "Именины":       return "person.text.rectangle"
        default:              return "calendar"
        }
    }
}

struct AddEventView: View {
    let userID: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var contactsService = ContactsService()

    @State private var recipientName = ""
    @State private var occasion = "День рождения"
    @State private var date = Date()
    @State private var notifyEnabled = true
    @State private var selectedContactID: String? = nil
    @State private var showContactsPicker = false
    @State private var contactBadge: String? = nil
    @State private var isCustomOccasion = false
    @State private var customOccasionText = ""

    let occasions = [
        "День рождения", "Новый год", "Свадьба", "Годовщина",
        "Выпускной", "8 Марта", "23 Февраля", "День матери",
        "День отца", "Крестины", "Юбилей", "Корпоратив",
        "Новоселье", "Именины"
    ]

    private let firebase = FirebaseService()
    var finalOccasion: String { isCustomOccasion ? customOccasionText : occasion }
    var canSave: Bool {
        if recipientName.isEmpty { return false }
        if isCustomOccasion { return !customOccasionText.trimmingCharacters(in: .whitespaces).isEmpty }
        return true
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Получатель").font(.headline)
                        TextField("Имя получателя", text: $recipientName).textFieldStyle(.roundedBorder)
                        if let badge = contactBadge {
                            HStack(spacing: 6) {
                                Image(systemName: "person.crop.circle.fill").foregroundColor(Color.theme.primary)
                                Text("Из контактов: \(badge)").font(.caption).foregroundColor(Color.theme.primary)
                                Spacer()
                                Button { selectedContactID = nil; contactBadge = nil } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(Color.theme.textSecondary)
                                }
                            }
                            .padding(8).background(Color.theme.tag).cornerRadius(8)
                        }
                        Button { showContactsPicker = true } label: {
                            Label("Выбрать из контактов", systemImage: "person.crop.circle.badge.plus")
                                .font(.subheadline).foregroundColor(Color.theme.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Повод").font(.headline)
                        FlowLayout(spacing: 8) {
                            ForEach(occasions, id: \.self) { occ in
                                Button { occasion = occ; isCustomOccasion = false; customOccasionText = "" } label: {
                                    Text(occ).font(.subheadline)
                                        .padding(.horizontal, 12).padding(.vertical, 7)
                                        .background(!isCustomOccasion && occasion == occ ? Color.theme.primary : Color.theme.tag)
                                        .foregroundColor(!isCustomOccasion && occasion == occ ? .white : Color.theme.text)
                                        .cornerRadius(14)
                                }
                            }
                            Button { withAnimation(.easeInOut(duration: 0.2)) { isCustomOccasion = true } } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus").font(.caption.weight(.bold))
                                    Text("Другое").font(.subheadline)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(isCustomOccasion ? Color.theme.primary : Color.theme.tag)
                                .foregroundColor(isCustomOccasion ? .white : Color.theme.text).cornerRadius(14)
                            }
                        }
                        if isCustomOccasion {
                            HStack(spacing: 8) {
                                TextField("Введите повод...", text: $customOccasionText).textFieldStyle(.roundedBorder)
                                Button { withAnimation { isCustomOccasion = false; customOccasionText = "" } } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(Color.theme.textSecondary).font(.title3)
                                }
                            }.transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }

                    DatePicker("Дата", selection: $date, displayedComponents: .date)
                    Toggle("Напомнить заранее", isOn: $notifyEnabled)
                    if notifyEnabled {
                        Text("Напомним за 3 дня и за 1 день до события")
                            .font(.caption).foregroundColor(Color.theme.textSecondary)
                    }

                    Button { saveEvent() } label: {
                        Text("Сохранить").fontWeight(.semibold)
                            .frame(maxWidth: .infinity).padding()
                            .background(canSave ? Color.theme.primary : Color.gray.opacity(0.3))
                            .foregroundColor(.white).cornerRadius(12)
                    }.disabled(!canSave)
                }
                .padding(24)
            }
            .navigationTitle("Новое событие")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Отмена") { dismiss() } }
            }
            .sheet(isPresented: $showContactsPicker) {
                EventContactPickerSheet(contactsService: contactsService) { candidate in
                    recipientName = candidate.name; selectedContactID = candidate.id; contactBadge = candidate.name
                    if let birthday = candidate.birthday { date = nextOccurrence(of: birthday); occasion = "День рождения"; isCustomOccasion = false }
                    showContactsPicker = false
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isCustomOccasion)
        }
    }

    private func nextOccurrence(of birthday: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.month, .day], from: birthday)
        components.year = calendar.component(.year, from: Date())
        guard var next = calendar.date(from: components) else { return birthday }
        if next < Date() { next = calendar.date(byAdding: .year, value: 1, to: next) ?? next }
        return next
    }

    private func saveEvent() {
        let event = GiftEvent(userID: userID, recipientID: "", recipientName: recipientName,
                              occasion: finalOccasion, date: date, budgetMin: 0, budgetMax: 0,
                              notifyEnabled: notifyEnabled, contactID: selectedContactID)
        Task { try? await firebase.addDocument(collection: "events", data: event, documentID: event.id) }
        if notifyEnabled {
            NotificationService.shared.scheduleEventReminder(
                title: "Завтра: \(finalOccasion)",
                body: "Не забудь подарок для \(recipientName)!",
                date: date, identifier: event.id)
            NotificationService.shared.scheduleEventReminder3Days(
                title: "Через 3 дня: \(finalOccasion)",
                body: "\(finalOccasion) у \(recipientName) скоро. Пора выбрать подарок!",
                date: date, identifier: event.id)
        }
        dismiss()
    }
}

struct EventContactPickerSheet: View {
    @ObservedObject var contactsService: ContactsService
    var onSelect: (ContactCandidate) -> Void
    @State private var searchText = ""
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
                        Image(systemName: "person.crop.circle.badge.xmark").font(.system(size: 52)).foregroundColor(Color.theme.textSecondary)
                        Text("Нет доступа к контактам").font(.headline)
                        Text("Разрешите доступ в\nНастройки → Конфиденциальность → Контакты")
                            .font(.subheadline).foregroundColor(Color.theme.textSecondary).multilineTextAlignment(.center)
                        Button("Открыть Настройки") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }.padding().background(Color.theme.primary).foregroundColor(.white).cornerRadius(12)
                    }.padding()
                } else if contactsService.isLoading {
                    ProgressView("Загрузка контактов…")
                } else {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(Color.theme.textSecondary)
                            TextField("Поиск", text: $searchText)
                        }
                        .padding(10).background(Color.theme.card).cornerRadius(10).padding(.horizontal).padding(.vertical, 8)
                        List(filtered) { candidate in
                            Button { onSelect(candidate) } label: {
                                HStack(spacing: 12) {
                                    if let data = candidate.imageData, let img = UIImage(data: data) {
                                        Image(uiImage: img).resizable().scaledToFill().frame(width: 40, height: 40).clipShape(Circle())
                                    } else {
                                        Circle().fill(Color.theme.tag).frame(width: 40, height: 40)
                                            .overlay(Text(candidate.name.prefix(1)).font(.subheadline).foregroundColor(Color.theme.primary))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(candidate.name).fontWeight(.medium)
                                        if let bd = candidate.birthdayString {
                                            Label(bd, systemImage: "gift.fill").font(.caption).foregroundColor(Color.theme.secondary)
                                        } else {
                                            Text("День рождения не указан").font(.caption).foregroundColor(Color.theme.textSecondary)
                                        }
                                    }
                                    Spacer()
                                }
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Выберите контакт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Отмена") { dismiss() } } }
        }
        .task { if contactsService.candidates.isEmpty { await contactsService.requestAccessAndLoad() } }
    }
}
