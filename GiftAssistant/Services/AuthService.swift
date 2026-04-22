import Foundation
import Combine
import FirebaseAuth

class AuthService: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEmailVerified = false
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.isEmailVerified = user?.isEmailVerified ?? false
        }
    }
    
    var isLoggedIn: Bool {
        currentUser != nil
    }
    
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        try await result.user.sendEmailVerification()
        await MainActor.run {
            self.currentUser = result.user
            self.isEmailVerified = false
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run {
            self.currentUser = result.user
            self.isEmailVerified = result.user.isEmailVerified
        }
    }
    
    func resendVerification() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification()
    }
    
    func checkVerification() async {
        guard let user = Auth.auth().currentUser else { return }
        try? await user.reload()
        let refreshedUser = Auth.auth().currentUser
        await MainActor.run {
            self.currentUser = refreshedUser
            self.isEmailVerified = refreshedUser?.isEmailVerified ?? false
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
        isEmailVerified = false
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
