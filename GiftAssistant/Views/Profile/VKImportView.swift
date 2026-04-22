import SwiftUI

struct VKImportView: View {
    let userID: String
    @ObservedObject var interestsService: InterestsService
    var onImport: ((Set<String>) -> Void)?

    @State private var profileInput = ""
    @State private var isLoading = false
    @State private var importResult: VKImportResult?
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private let vkService = VKService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#0077FF").opacity(0.1))
                                .frame(width: 80, height: 80)
                            Text("VK")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "#0077FF"))
                        }
                        Text("Import from VK")
                            .font(.title2).fontWeight(.bold)
                            .foregroundColor(Color.theme.primary)
                        Text("Enter a VK profile link to import public interests")
                            .font(.subheadline)
                            .foregroundColor(Color.theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 8)

                    // Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile link or username").font(.headline)

                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(Color.theme.textSecondary)
                            TextField("vk.com/username or username", text: $profileInput)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            if !profileInput.isEmpty {
                                Button { profileInput = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color.theme.textSecondary)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.theme.card)
                        .cornerRadius(12)

                        Text("Examples: vk.com/durov, durov, id1")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                    }
                    .padding(.horizontal)

                    // Import button
                    Button {
                        Task { await runImport() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white).padding(.trailing, 4)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text(isLoading ? "Importing..." : "Import Interests")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(profileInput.isEmpty || isLoading
                                    ? Color.gray.opacity(0.3) : Color(hex: "#0077FF"))
                        .foregroundColor(.white).cornerRadius(14)
                    }
                    .disabled(profileInput.isEmpty || isLoading)
                    .padding(.horizontal)

                    // Error
                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                            Text(error).font(.subheadline).foregroundColor(.red)
                        }
                        .padding().background(Color.red.opacity(0.08)).cornerRadius(10)
                        .padding(.horizontal)
                    }

                    // Result
                    if let result = importResult {
                        VStack(spacing: 16) {

                            // User card
                            HStack(spacing: 12) {
                                if let photoURL = result.photoURL, let url = URL(string: photoURL) {
                                    AsyncImage(url: url) { img in
                                        img.resizable().scaledToFill()
                                            .frame(width: 56, height: 56).clipShape(Circle())
                                    } placeholder: {
                                        AvatarCircle(name: result.displayName, size: 56)
                                    }
                                } else {
                                    AvatarCircle(name: result.displayName, size: 56)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.displayName).font(.headline)
                                    Text("\(result.mappedTags.count) interests found")
                                        .font(.subheadline).foregroundColor(Color.theme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.theme.success).font(.title2)
                            }
                            .padding()
                            .background(Color.theme.card).cornerRadius(12)
                            .padding(.horizontal)

                            // Mapped tags
                            if !result.mappedTags.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Matched interests (\(result.mappedTags.count))")
                                        .font(.headline).padding(.horizontal)

                                    FlowLayout(spacing: 8) {
                                        ForEach(result.mappedTags.sorted(), id: \.self) { tag in
                                            HStack(spacing: 4) {
                                                Image(systemName: "star.fill").font(.caption2)
                                                Text(tag).font(.caption).fontWeight(.medium)
                                            }
                                            .padding(.horizontal, 10).padding(.vertical, 6)
                                            .background(Color.theme.primary.opacity(0.1))
                                            .foregroundColor(Color.theme.primary).cornerRadius(20)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            // Raw data preview
                            if !result.rawInterests.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Raw data from VK (\(result.rawInterests.count) items)")
                                        .font(.caption).foregroundColor(Color.theme.textSecondary)
                                        .padding(.horizontal)
                                    Text(result.rawInterests.prefix(15).joined(separator: ", "))
                                        .font(.caption).foregroundColor(Color.theme.textSecondary)
                                        .padding(.horizontal)
                                }
                            }

                            // Apply button
                            Button {
                                applyImport(result)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: showSuccess ? "checkmark.circle.fill" : "plus.circle.fill")
                                    Text(showSuccess ? "Applied!" : "Add to Profile Interests")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity).padding()
                                .background(showSuccess ? Color.theme.success : Color.theme.primary)
                                .foregroundColor(.white).cornerRadius(14)
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 8)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("VK Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Actions

    private func runImport() async {
        isLoading = true
        errorMessage = nil
        importResult = nil

        do {
            let result = try await vkService.importInterests(from: profileInput)
            importResult = result
        } catch let error as VKError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func applyImport(_ result: VKImportResult) {
        // Merge with existing interests
        result.mappedTags.forEach { interestsService.selectedInterests.insert($0) }

        // Save to Firestore
        Task { await interestsService.saveInterests(userID: userID) }

        onImport?(result.mappedTags)

        withAnimation { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
    }
}
