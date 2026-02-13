import SwiftUI

struct EditProfileView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var name: String = ""
    @State private var showEmailView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            if let user = authManager.currentUser {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(String(user.name.prefix(1)).uppercased())
                                            .font(.system(size: 40, weight: .semibold))
                                            .foregroundColor(Color("All"))
                                    )
                                
                                Text(user.name)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(Color("All"))
                                
                                Text(user.email)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("All").opacity(0.6))
                            }
                        }
                        .padding(.top, 30)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color("All"))
                            
                            HStack {
                                TextField("", text: $name)
                                    .font(.system(size: 17))
                                    .foregroundColor(Color("All"))
                                
                                if !name.isEmpty && name != authManager.currentUser?.name {
                                    Button(action: {
                                        if var user = authManager.currentUser {
                                            user.name = name
                                            authManager.updateUser(user)
                                        }
                                    }) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(Color("All"))
                                            .frame(width: 32, height: 32)
                                            .background(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color("All"))
                            
                            Button(action: {
                                showEmailView = true
                            }) {
                                HStack {
                                    if let user = authManager.currentUser {
                                        Text(user.email)
                                            .font(.system(size: 17))
                                            .foregroundColor(Color("All"))
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("All").opacity(0.5))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                }
            }
            .navigationTitle("Edit profile")
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
            .onAppear {
                if let user = authManager.currentUser {
                    name = user.name
                }
            }
            .sheet(isPresented: $showEmailView) {
                EmailView(authManager: authManager)
            }
        }
    }
}
