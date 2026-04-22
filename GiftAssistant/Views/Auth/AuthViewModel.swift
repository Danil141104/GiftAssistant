import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showProfileSetup = false
    @Published var newUserID: String?
    
    let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func signUp() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signUp(email: email, password: password)
                if let uid = authService.currentUser?.uid {
                    newUserID = uid
                    showProfileSetup = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
