import SwiftUI

struct SettingsView: View {
    @ObservedObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showEditProfile = false
    @State private var showMode = false
    @State private var notificationsEnabled = true
    @State private var showLogoutConfirmation = false
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color("All"))
                        
                        Spacer()
                        
                        Button(action: {
                            showLogoutConfirmation = true
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 20))
                                .foregroundColor(Color("All"))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            if let user = authManager.currentUser {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(String(user.name.prefix(1)).uppercased())
                                            .font(.system(size: 32, weight: .semibold))
                                            .foregroundColor(Color("All"))
                                    )
                                
                                Text(user.name)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color("All"))
                                
                                Text(user.email)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color("All").opacity(0.6))
                                
                                Button(action: {
                                    showEditProfile = true
                                }) {
                                    HStack {
                                        Text("Edit Profile")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("All").opacity(0.5))
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(Color("All"))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                                    .cornerRadius(12)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("General")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color("All"))
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                Button(action: {
                                    showMode = true
                                }) {
                                    HStack {
                                        Image(systemName: "sun.max.fill")
                                            .foregroundColor(Color("All"))
                                            .frame(width: 24)
                                        Text("Mode")
                                            .foregroundColor(Color("All"))
                                        Spacer()
                                        Text(authManager.theme.rawValue.capitalized)
                                            .foregroundColor(Color("All").opacity(0.6))
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("All").opacity(0.5))
                                    }
                                    .font(.system(size: 17))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                
                                Divider()
                                    .padding(.leading, 56)
                                
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(Color("All"))
                                        .frame(width: 24)
                                    Text("Notifications")
                                        .foregroundColor(Color("All"))
                                    Spacer()
                                    Toggle("", isOn: $notificationsEnabled)
                                        .labelsHidden()
                                        .tint(Color("All"))
                                }
                                .font(.system(size: 17))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                            }
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Support")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color("All"))
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "star")
                                            .foregroundColor(Color("All"))
                                            .frame(width: 24)
                                        Text("Rate Us")
                                            .foregroundColor(Color("All"))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("All").opacity(0.5))
                                    }
                                    .font(.system(size: 17))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                
                                Divider()
                                    .padding(.leading, 56)
                                
                                Button(action: {}) {
                                    HStack {
                                        Image(systemName: "questionmark.circle")
                                            .foregroundColor(Color("All"))
                                            .frame(width: 24)
                                        Text("Help Center")
                                            .foregroundColor(Color("All"))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("All").opacity(0.5))
                                    }
                                    .font(.system(size: 17))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                            }
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color("All"))
                                .padding(.horizontal, 24)
                            
                            VStack(spacing: 0) {
                                Button(action: {}) {
                                    HStack {
                                        Text("Terms of Use")
                                            .foregroundColor(Color("All"))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("All").opacity(0.5))
                                    }
                                    .font(.system(size: 17))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                
                                Divider()
                                
                                Button(action: {}) {
                                    HStack {
                                        Text("Privacy Policy")
                                            .foregroundColor(Color("All"))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("All").opacity(0.5))
                                    }
                                    .font(.system(size: 17))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Version 1.1.6")
                                        .foregroundColor(Color("All"))
                                    Spacer()
                                }
                                .font(.system(size: 17))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                            }
                            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .foregroundStyle(Color("All"))
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(authManager: authManager)
        }
        .sheet(isPresented: $showMode) {
            ModeView(authManager: authManager)
        }
        .confirmationDialog("Sign Out", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}
