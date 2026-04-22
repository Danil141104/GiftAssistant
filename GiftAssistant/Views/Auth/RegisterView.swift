import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.primary)
                
                VStack(spacing: 14) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    viewModel.signUp()
                } label: {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.theme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .background(Color.theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showProfileSetup) {
                if let uid = viewModel.newUserID {
                    UserProfileSetupView(userID: uid, isOnboarding: true) {
                        viewModel.showProfileSetup = false
                        dismiss()
                    }
                }
            }
        }
    }
}
