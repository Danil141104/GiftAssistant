import SwiftUI

struct CreateRoomView: View {
    let userID: String
    @ObservedObject var viewModel: GroupRoomViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var recipientName = ""
    @State private var occasion = "День рождения"
    @State private var budgetGoal = ""
    @State private var createdCode: String?
    
    let occasions = ["День рождения", "Новый год", "Свадьба", "Годовщина", "Выпускной", "8 Марта", "23 Февраля", "Другое"]
    let presets = [3000, 5000, 10000, 20000]
    
    var body: some View {
        NavigationStack {
            if let code = createdCode {
                // Success screen
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.theme.success)
                    
                    Text("Room Created!")
                        .font(.title2).fontWeight(.bold)
                    
                    Text("Invite code:")
                        .foregroundColor(Color.theme.textSecondary)
                    
                    Text(code)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.theme.primary)
                        .tracking(6)
                    
                    Text("Share this code with friends\nso they can join")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = code
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.theme.tag).foregroundColor(Color.theme.primary).cornerRadius(12)
                        }
                        
                        Button { shareCode(code) } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.theme.primary).foregroundColor(.white).cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.theme.secondary)
                }
                .padding(24)
            } else {
                // Create form
                ScrollView {
                    VStack(spacing: 20) {
                        // Recipient
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Who is the gift for?").font(.headline)
                            TextField("Recipient name", text: $recipientName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Occasion
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Occasion").font(.headline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(occasions, id: \.self) { occ in
                                        Button { occasion = occ } label: {
                                            Text(occ).font(.subheadline).fontWeight(.medium)
                                                .padding(.horizontal, 14).padding(.vertical, 8)
                                                .background(occasion == occ ? Color.theme.primary : Color.theme.tag)
                                                .foregroundColor(occasion == occ ? .white : Color.theme.text)
                                                .cornerRadius(16)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Budget
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Goal Amount").font(.headline)
                            
                            HStack(spacing: 8) {
                                ForEach(presets, id: \.self) { amount in
                                    Button { budgetGoal = "\(amount)" } label: {
                                        Text("\(amount / 1000)k ₽").font(.caption).fontWeight(.medium)
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(budgetGoal == "\(amount)" ? Color.theme.primary : Color.theme.tag)
                                            .foregroundColor(budgetGoal == "\(amount)" ? .white : Color.theme.primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            
                            TextField("Or enter amount ₽", text: $budgetGoal)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                        }
                        
                        // Create button
                        Button {
                            guard let goal = Double(budgetGoal), !recipientName.isEmpty else { return }
                            let code = viewModel.createRoomAndReturnCode(
                                organizerID: userID,
                                recipientName: recipientName,
                                occasion: occasion,
                                budgetGoal: goal
                            )
                            createdCode = code
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Room").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity).padding()
                            .background(canCreate ? Color.theme.primary : Color.gray.opacity(0.3))
                            .foregroundColor(.white).cornerRadius(12)
                        }
                        .disabled(!canCreate)
                    }
                    .padding(24)
                }
                .navigationTitle("New Room")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }
    
    var canCreate: Bool {
        !recipientName.isEmpty && Double(budgetGoal) != nil && Double(budgetGoal)! > 0
    }
    
    private func shareCode(_ code: String) {
        let text = "Join the gift collection for \(recipientName)!\nOccasion: \(occasion)\nRoom code: \(code)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let root = window.rootViewController {
            root.present(av, animated: true)
        }
    }
}
