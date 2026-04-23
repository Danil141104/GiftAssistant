import SwiftUI

struct WizardStepTags: View {
    @ObservedObject var viewModel: WizardViewModel
    @State private var customTag = ""

    let suggestedTags = [
        "Техника", "Гаджеты", "Музыка", "Книги", "Кулинария",
        "Путешествия", "Спорт", "Фитнес", "Мода", "Фото",
        "Творчество", "DIY", "Игры", "Развлечения", "Красота",
        "Уход", "Дом", "Уют", "Сад", "Здоровье",
        "Образование", "Стиль", "Аксессуары", "Еда", "Кофе"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Что их интересует?").font(.title2).fontWeight(.bold).foregroundColor(Color.theme.primary)
                Text("Выберите интересы для лучших рекомендаций").foregroundColor(Color.theme.textSecondary)

                if let recipient = viewModel.selectedRecipient, !recipient.tags.isEmpty {
                    let recipientSuggestions = recipient.tags.filter { !viewModel.selectedTags.contains($0) }
                    if !recipientSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.fill").font(.caption).foregroundColor(Color.theme.primary)
                                Text("Интересы \(recipient.name):").font(.subheadline).fontWeight(.medium).foregroundColor(Color.theme.primary)
                                Spacer()
                                Button("Добавить все") { recipientSuggestions.forEach { viewModel.selectedTags.insert($0) } }
                                    .font(.caption).foregroundColor(Color.theme.secondary)
                            }
                            FlowLayout(spacing: 8) {
                                ForEach(recipientSuggestions, id: \.self) { tag in
                                    TagChipView(label: "＋ \(tag)", isSelected: false) { viewModel.selectedTags.insert(tag) }
                                }
                            }
                        }
                        .padding(12).background(Color.theme.primary.opacity(0.06)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.theme.primary.opacity(0.2), lineWidth: 1))
                    }
                }

                FlowLayout(spacing: 8) {
                    ForEach(suggestedTags, id: \.self) { tag in
                        TagChipView(label: tag, isSelected: viewModel.selectedTags.contains(tag)) {
                            if viewModel.selectedTags.contains(tag) { viewModel.selectedTags.remove(tag) }
                            else { viewModel.selectedTags.insert(tag) }
                        }
                    }
                }

                HStack {
                    TextField("Свой тег...", text: $customTag).textFieldStyle(.roundedBorder)
                    Button {
                        guard !customTag.isEmpty else { return }
                        viewModel.selectedTags.insert(customTag); customTag = ""
                    } label: { Image(systemName: "plus.circle.fill").font(.title2).foregroundColor(Color.theme.primary) }
                }

                if !viewModel.selectedTags.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Выбрано (\(viewModel.selectedTags.count)):").font(.caption).foregroundColor(Color.theme.textSecondary)
                        Text(viewModel.selectedTags.sorted().joined(separator: ", ")).font(.caption).foregroundColor(Color.theme.textSecondary)
                    }
                }
                Spacer()
            }.padding()
        }
    }
}
