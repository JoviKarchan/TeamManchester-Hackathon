import Foundation
import SwiftUI
import Combine

enum AppTheme: String, Codable {
    case system
    case light
    case dark
}

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var theme: AppTheme = .system
    
    private let userDefaults = UserDefaults.standard
    private let userKey = "currentUser"
    private let themeKey = "appTheme"
    
    init() {
        loadUser()
        loadTheme()
    }
    
    func signInWithApple() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let user = User(
                name: "Jovi Kaarchan",
                email: "jovi.udayakumarbabu@icloud.com",
                profileImageURL: nil
            )
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
            self.saveUser()
        }
    }
    
    func signInWithGoogle() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let user = User(
                name: "Eugenia Babajanyan",
                email: "eugenia.bj@gmail.com",
                profileImageURL: nil
            )
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false
            self.saveUser()
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: userKey)
    }
    
    func updateUser(_ user: User) {
        currentUser = user
        saveUser()
    }
    
    func updateEmail(_ newEmail: String) {
        guard var user = currentUser else { return }
        user.email = newEmail
        currentUser = user
        saveUser()
    }
    
    func updateTheme(_ theme: AppTheme) {
        self.theme = theme
        userDefaults.set(theme.rawValue, forKey: themeKey)
    }
    
    private func saveUser() {
        if let encoded = try? JSONEncoder().encode(currentUser) {
            userDefaults.set(encoded, forKey: userKey)
        }
    }
    
    private func loadUser() {
        if let data = userDefaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    private func loadTheme() {
        if let themeString = userDefaults.string(forKey: themeKey),
           let loadedTheme = AppTheme(rawValue: themeString) {
            theme = loadedTheme
        }
    }
}
