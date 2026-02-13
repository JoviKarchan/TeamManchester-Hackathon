import SwiftUI

@main
struct experimentingApp: App {
    @StateObject private var historyStore = HistoryStore()
    @StateObject private var authManager = AuthManager()

    init() {
        let tabBar = UITabBar.appearance()
        tabBar.tintColor = UIColor(named: "All")
        tabBar.unselectedItemTintColor = UIColor.systemGray
    }

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                VideoLoaderView()
                    .environmentObject(historyStore)
                    .environmentObject(authManager)
                    .preferredColorScheme(authManager.theme == .system ? nil : (authManager.theme == .dark ? .dark : .light))
            } else {
                LoginView(authManager: authManager)
                    .preferredColorScheme(authManager.theme == .system ? nil : (authManager.theme == .dark ? .dark : .light))
            }
        }
    }
}
