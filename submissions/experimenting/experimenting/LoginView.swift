import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.95, blue: 0.97)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Text("Findly")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 100)
                
                VStack(spacing: 16) {
                    Button(action: {
                        isLoading = true
                        authManager.signInWithApple()
                    }) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                            Text("Continue with Apple")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading || authManager.isLoading)
                    
                    Button(action: {
                        isLoading = true
                        authManager.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                            Text("Continue with Google")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading || authManager.isLoading)
                    
                    Text("By tapping Continue, you agree to our Terms and Privacy Policy.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            
            if isLoading || authManager.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        
                        Text("Signing in...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(16)
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) { authenticated in
            if authenticated {
                isLoading = false
            }
        }
    }
}
