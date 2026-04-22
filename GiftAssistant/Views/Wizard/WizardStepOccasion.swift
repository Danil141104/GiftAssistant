import SwiftUI

struct WizardStepOccasion: View {
    @ObservedObject var viewModel: WizardViewModel

    @State private var showCustomField = false
    @State private var customOccasion = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("What's the occasion?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.primary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(viewModel.occasions, id: \.self) { occasion in
                        Button {
                            viewModel.selectedOccasion = occasion
                            showCustomField = false
                            customOccasion = ""
                        } label: {
                            HStack {
                                Image(systemName: iconFor(occasion))
                                Text(occasion)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                viewModel.selectedOccasion == occasion && !showCustomField
                                    ? Color.theme.primary : Color.theme.card
                            )
                            .foregroundColor(
                                viewModel.selectedOccasion == occasion && !showCustomField
                                    ? .white : Color.theme.text
                            )
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                        }
                    }

                    // Custom occasion button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showCustomField = true
                            if !customOccasion.isEmpty {
                                viewModel.selectedOccasion = customOccasion
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: showCustomField ? "pencil.circle.fill" : "plus.circle")
                            Text(showCustomField && !customOccasion.isEmpty ? customOccasion : "Custom")
                                .fontWeight(.medium)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(showCustomField ? Color.theme.primary : Color.theme.card)
                        .foregroundColor(showCustomField ? .white : Color.theme.secondary)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                }

                // Custom occasion input field
                if showCustomField {
                    HStack(spacing: 8) {
                        TextField("Enter occasion name...", text: $customOccasion)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: customOccasion) { value in
                                if !value.isEmpty {
                                    viewModel.selectedOccasion = value
                                }
                            }

                        Button {
                            withAnimation {
                                showCustomField = false
                                customOccasion = ""
                                if viewModel.selectedOccasion == customOccasion {
                                    viewModel.selectedOccasion = ""
                                }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.theme.textSecondary)
                                .font(.title3)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
            .padding()
        }
        .animation(.easeInOut(duration: 0.2), value: showCustomField)
    }

    func iconFor(_ occasion: String) -> String {
        switch occasion {
        case "День рождения": return "birthday.cake"
        case "Новый год":     return "snowflake"
        case "Свадьба":       return "heart.circle"
        case "Юбилей":        return "star.circle.fill"
        case "Выпускной":     return "graduationcap"
        case "8 марта":       return "staroflife.fill"
        case "23 февраля":    return "star.fill"
        case "Корпоратив":    return "building.2"
        case "Просто так":    return "gift"
        default:              return "calendar"
        }
    }
}
