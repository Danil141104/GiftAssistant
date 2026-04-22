import SwiftUI

struct InterestsQuestionnaireView: View {
    let userID: String
    @ObservedObject var service: InterestsService
    @Environment(\.dismiss) private var dismiss

    @State private var isSaving = false
    @State private var showVKImport = false

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Interests")
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(Color.theme.primary)
                        Text("Select everything you enjoy — this improves gift recommendations")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    .padding(.horizontal)

                    // VK Import button
                    Button {
                        showVKImport = true
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#0077FF"))
                                    .frame(width: 32, height: 32)
                                Text("VK")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import from VK")
                                    .font(.subheadline).fontWeight(.semibold)
                                    .foregroundColor(Color.theme.text)
                                Text("Auto-detect interests from public profile")
                                    .font(.caption)
                                    .foregroundColor(Color.theme.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption).foregroundColor(Color.theme.textSecondary)
                        }
                        .padding(12)
                        .background(Color.theme.card)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#0077FF").opacity(0.3), lineWidth: 1))
                    }
                    .padding(.horizontal)

                    // Selected count
                    if !service.selectedInterests.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(Color.theme.success)
                            Text("Selected: \(service.selectedInterests.count)")
                                .font(.subheadline).fontWeight(.medium).foregroundColor(Color.theme.success)
                            Spacer()
                            Button("Reset") {
                                withAnimation { service.selectedInterests.removeAll() }
                            }
                            .font(.subheadline).foregroundColor(Color.theme.textSecondary)
                        }
                        .padding(.horizontal).transition(.opacity)
                    }

                    // Grid
                    if service.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(InterestsService.allCategories, id: \.name) { category in
                                InterestCell(
                                    icon: category.icon,
                                    name: category.name,
                                    isSelected: service.selectedInterests.contains(category.name)
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        service.toggle(category.name)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Save button
                    Button {
                        Task { await saveAndDismiss() }
                    } label: {
                        HStack {
                            if isSaving { ProgressView().tint(.white).padding(.trailing, 4) }
                            Text(isSaving ? "Saving..." : "Save Interests").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(service.selectedInterests.isEmpty ? Color.gray.opacity(0.3) : Color.theme.primary)
                        .foregroundColor(.white).cornerRadius(14)
                    }
                    .disabled(service.selectedInterests.isEmpty || isSaving)
                    .padding(.horizontal).padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("Interests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: service.selectedInterests)
            .sheet(isPresented: $showVKImport) {
                VKImportView(userID: userID, interestsService: service)
            }
        }
    }

    private func saveAndDismiss() async {
        isSaving = true
        await service.saveInterests(userID: userID)
        isSaving = false
        dismiss()
    }
}

// MARK: - Interest Cell

struct InterestCell: View {
    let icon: String
    let name: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.theme.primary : Color.theme.tag)
                        .frame(width: 52, height: 52)
                    Image(systemName: icon).font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : Color.theme.primary)
                }
                .overlay(
                    Group {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 16))
                                .foregroundColor(Color.theme.success)
                                .background(Circle().fill(.white).frame(width: 14, height: 14))
                                .offset(x: 18, y: -18)
                        }
                    }
                )
                Text(name).font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? Color.theme.primary : Color.theme.text)
                    .multilineTextAlignment(.center).lineLimit(2)
            }
            .padding(.vertical, 12).frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.theme.primary.opacity(0.08) : Color.theme.card)
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? Color.theme.primary : Color.clear, lineWidth: 2))
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
