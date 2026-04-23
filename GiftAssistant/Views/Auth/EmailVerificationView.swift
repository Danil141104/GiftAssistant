import SwiftUI
import FirebaseAuth

struct EmailVerificationView: View {
    let authService: AuthService
    @State private var isChecking = false
    @State private var showResent = false
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "envelope.badge").font(.system(size: 70)).foregroundColor(Color.theme.primary)
            Text("Подтвердите email").font(.title).fontWeight(.bold).foregroundColor(Color.theme.primary)
            Text("Мы отправили письмо на").foregroundColor(Color.theme.textSecondary)
            Text(authService.currentUser?.email ?? "").font(.headline).foregroundColor(Color.theme.text)
            Text("Откройте письмо и перейдите по ссылке,\nзатем нажмите кнопку ниже")
                .font(.subheadline).foregroundColor(Color.theme.textSecondary).multilineTextAlignment(.center)
            Spacer()
            Button { checkEmail() } label: {
                HStack {
                    if isChecking { ProgressView().tint(.white) }
                    else { Image(systemName: "checkmark.circle"); Text("Я подтвердил email") }
                }
                .fontWeight(.semibold).frame(maxWidth: .infinity).padding()
                .background(Color.theme.primary).foregroundColor(.white).cornerRadius(14)
            }
            Button { resendEmail() } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(showResent ? "Письмо отправлено!" : "Отправить письмо ещё раз")
                }
                .font(.subheadline).foregroundColor(showResent ? Color.theme.success : Color.theme.secondary)
            }
            .disabled(showResent)
            Button { authService.signOut() } label: {
                Text("Выйти и использовать другой email").font(.caption).foregroundColor(Color.theme.textSecondary)
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Color.theme.background.ignoresSafeArea())
        .onAppear { startAutoCheck() }
        .onDisappear { timer?.invalidate() }
    }
    
    private func checkEmail() {
        isChecking = true
        Task { await authService.checkVerification(); isChecking = false }
    }
    private func resendEmail() {
        Task {
            try? await authService.resendVerification()
            showResent = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { showResent = false }
        }
    }
    private func startAutoCheck() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task { await authService.checkVerification() }
        }
    }
}
