import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showRegister = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.theme.primary)
                
                Text("GiftAssistant")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.primary)
                
                Text("Find the perfect gift")
                    .foregroundColor(Color.theme.textSecondary)
                
                Spacer()
                
                VStack(spacing: 14) {
                    TextField("Email", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button {
                    viewModel.signIn()
                } label: {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color.theme.primary)
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Button("Don't have an account? Sign Up") {
                    showRegister = true
                }
                .foregroundColor(Color.theme.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .background(Color.theme.background.ignoresSafeArea())
            .sheet(isPresented: $showRegister) {
                RegisterView(viewModel: viewModel)
            }
        }
    }
}
