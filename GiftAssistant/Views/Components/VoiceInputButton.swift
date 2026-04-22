import SwiftUI

struct VoiceInputButton: View {
    @ObservedObject var voiceService: VoiceInputService
    var onResult: (VoiceInputResult) -> Void

    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Голосовой ввод")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.theme.primary, Color.theme.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .shadow(color: Color.theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .sheet(isPresented: $showSheet) {
            VoiceInputSheet(voiceService: voiceService) { result in
                showSheet = false
                onResult(result)
            }
        }
    }
}

// MARK: - Voice Input Sheet

struct VoiceInputSheet: View {
    @ObservedObject var voiceService: VoiceInputService
    var onApply: (VoiceInputResult) -> Void

    @State private var hasRequestedPermissions = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 28) {

                VStack(spacing: 8) {
                    Text("Скажите, например:")
                        .font(.subheadline)
                        .foregroundColor(Color.theme.textSecondary)
                    Text("«Хочу подарить Александру, мужчина, друг, день рождения, бюджет 3000»")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.theme.primary)
                        .padding(.horizontal)
                }
                .padding(.top, 8)

                ZStack {
                    if voiceService.isRecording {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .stroke(Color.theme.primary.opacity(0.3 - Double(i) * 0.08), lineWidth: 2)
                                .scaleEffect(voiceService.isRecording ? 1.0 + CGFloat(i) * 0.35 : 1.0)
                                .animation(
                                    .easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.2),
                                    value: voiceService.isRecording
                                )
                                .frame(width: 90, height: 90)
                        }
                    }

                    Circle()
                        .fill(voiceService.isRecording ? Color.red : Color.theme.primary)
                        .frame(width: 90, height: 90)
                        .shadow(
                            color: (voiceService.isRecording ? Color.red : Color.theme.primary).opacity(0.4),
                            radius: 12, x: 0, y: 6
                        )

                    Image(systemName: voiceService.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                .onTapGesture {
                    if voiceService.isRecording {
                        voiceService.stopRecording()
                    } else {
                        voiceService.startRecording()
                    }
                }

                Text(voiceService.isRecording ? "Говорите… нажмите чтобы остановить" : "Нажмите для записи")
                    .font(.subheadline)
                    .foregroundColor(voiceService.isRecording ? .red : Color.theme.textSecondary)

                if !voiceService.recognizedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Распознано:")
                            .font(.caption)
                            .foregroundColor(Color.theme.textSecondary)
                        Text(voiceService.recognizedText)
                            .font(.body)
                            .foregroundColor(Color.theme.text)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.card)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                if let result = voiceService.parsedResult {
                    ParsedResultPreview(result: result)
                        .padding(.horizontal)

                    Button {
                        onApply(result)
                    } label: {
                        Label("Применить", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.theme.success)
                            .cornerRadius(14)
                            .padding(.horizontal)
                    }
                }

                if let error = voiceService.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Голосовой ввод")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
        .task {
            if !hasRequestedPermissions {
                hasRequestedPermissions = true
                await voiceService.requestPermissions()
            }
        }
    }
}

// MARK: - Parsed Result Preview

struct ParsedResultPreview: View {
    let result: VoiceInputResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Распарсено:")
                .font(.caption)
                .foregroundColor(Color.theme.textSecondary)

            FlowLayout(spacing: 8) {
                if let name = result.name {
                    PreviewChip(icon: "person.fill", text: name)
                }
                if let gender = result.gender {
                    PreviewChip(icon: "person.2.fill", text: gender == "Male" ? "Мужчина" : "Женщина")
                }
                if let age = result.age {
                    PreviewChip(icon: "calendar", text: "\(age) лет")
                }
                if let rel = result.relationship {
                    PreviewChip(icon: "heart.fill", text: rel)
                }
                if let occ = result.occasion {
                    PreviewChip(icon: "gift.fill", text: occ)
                }
                if let max = result.budgetMax {
                    let minStr = result.budgetMin.map { "от \(Int($0)) " } ?? ""
                    PreviewChip(icon: "rublesign", text: "\(minStr)до \(Int(max)) ₽")
                }
                ForEach(result.tags, id: \.self) { tag in
                    PreviewChip(icon: "tag.fill", text: tag)
                }
            }
        }
        .padding()
        .background(Color.theme.tag.opacity(0.5))
        .cornerRadius(12)
    }
}

struct PreviewChip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.theme.primary.opacity(0.12))
        .foregroundColor(Color.theme.primary)
        .cornerRadius(20)
    }
}
