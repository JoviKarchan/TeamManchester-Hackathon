import SwiftUI

struct EmailView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var newEmail: String = ""
    @State private var isValidEmail = true
    @State private var showError = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Email")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color("All"))
                            
                            if let user = authManager.currentUser {
                                Text(user.email)
                                    .font(.system(size: 17))
                                    .foregroundColor(Color("All").opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 30)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Email")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color("All"))
                            
                            HStack {
                                TextField("Enter new email address", text: $newEmail)
                                    .font(.system(size: 17))
                                    .foregroundColor(Color("All"))
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .onChange(of: newEmail) { oldValue, newValue in
                                        validateEmail(newValue)
                                    }
                                
                                if !newEmail.isEmpty && isValidEmail && newEmail != authManager.currentUser?.email {
                                    Button(action: {
                                        saveEmail()
                                    }) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color("All"))
                                            .frame(width: 32, height: 32)
                                            .background(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                                            .clipShape(Circle())
                                    }
                                    .disabled(isSaving)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(showError && !isValidEmail ? Color.red : Color.clear, lineWidth: 1)
                            )
                            
                            if showError && !isValidEmail {
                                Text("Please enter the correct Email")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Text("A verification email will be sent to your new email address. You will need to click the link in the email to confirm the change.")
                            .font(.system(size: 14))
                            .foregroundColor(Color("All").opacity(0.6))
                            .padding(.horizontal, 24)
                        
                        Button(action: {
                            saveEmail()
                        }) {
                            Text("Save")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.black)
                                .cornerRadius(14)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .disabled(!isValidEmail || newEmail.isEmpty || isSaving)
                        .opacity((!isValidEmail || newEmail.isEmpty || isSaving) ? 0.5 : 1)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("All"))
                            .frame(width: 32, height: 32)
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                            .clipShape(Circle())
                    }
                }
            }
            .foregroundStyle(Color("All"))
        }
    }
    
    private func validateEmail(_ email: String) {
        if email.isEmpty {
            isValidEmail = true
            showError = false
            return
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        isValidEmail = emailPredicate.evaluate(with: email)
        
        if !isValidEmail {
            showError = true
        } else {
            showError = false
        }
    }
    
    private func saveEmail() {
        guard isValidEmail && !newEmail.isEmpty else { return }
        
        isSaving = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            authManager.updateEmail(newEmail)
            isSaving = false
            dismiss()
        }
    }
}
