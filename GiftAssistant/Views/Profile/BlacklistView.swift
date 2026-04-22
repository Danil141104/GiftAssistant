import SwiftUI

struct BlacklistView: View {
    @EnvironmentObject var blacklistService: BlacklistService
    @State private var newItem = ""

    let suggestions = [
        "Носки", "Гель для душа", "Рамка для фото",
        "Статуэтки", "Мягкие игрушки", "Свечи",
        "Ежедневник", "Кружка", "Брелок", "Магнит"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Add new
                VStack(alignment: .leading, spacing: 10) {
                    Text("Add to list")
                        .font(.headline)
                    HStack {
                        TextField("E.g. socks, mug...", text: $newItem)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            blacklistService.add(newItem)
                            newItem = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color.theme.primary)
                        }
                        .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .cardStyle()

                // Suggestions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Popular options")
                        .font(.headline)
                    FlowLayout(spacing: 8) {
                        ForEach(suggestions.filter { suggestion in
                            !blacklistService.blacklist.contains(where: { $0.lowercased() == suggestion.lowercased() })
                        }, id: \.self) { suggestion in
                            Button {
                                blacklistService.add(suggestion)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus").font(.caption2)
                                    Text(suggestion).font(.caption)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(Color.theme.tag)
                                .foregroundColor(Color.theme.primary)
                                .cornerRadius(16)
                            }
                        }
                    }
                }
                .cardStyle()

                // Current list
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Do Not Gift List")
                            .font(.headline)
                        Spacer()
                        Text("\(blacklistService.blacklist.count)")
                            .font(.caption).fontWeight(.semibold)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red).cornerRadius(10)
                    }

                    if blacklistService.blacklist.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "hand.thumbsdown")
                                    .font(.title).foregroundColor(Color.theme.textSecondary)
                                Text("List is empty")
                                    .foregroundColor(Color.theme.textSecondary)
                                Text("Add gifts that should\nnever be given")
                                    .font(.caption)
                                    .foregroundColor(Color.theme.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else {
                        ForEach(blacklistService.blacklist, id: \.self) { item in
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red.opacity(0.6))
                                Text(item).foregroundColor(Color.theme.text)
                                Spacer()
                                Button {
                                    withAnimation { blacklistService.removeItem(item) }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption).foregroundColor(Color.theme.textSecondary)
                                }
                            }
                            .padding(.vertical, 6)
                            if item != blacklistService.blacklist.last { Divider() }
                        }
                    }
                }
                .cardStyle()
            }
            .padding(.horizontal).padding(.top, 8)
        }
        .background(Color.theme.background.ignoresSafeArea())
        .navigationTitle("Do Not Gift")
    }
}
