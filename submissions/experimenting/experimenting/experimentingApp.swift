import SwiftUI

@main
struct experimentingApp: App {
    @StateObject private var historyStore = HistoryStore()

    init() {
        let tabBar = UITabBar.appearance()
        tabBar.tintColor = UIColor(named: "All")
        tabBar.unselectedItemTintColor = UIColor.systemGray
    }

    var body: some Scene {
        WindowGroup {
            VideoLoaderView()
                .environmentObject(historyStore)
        }
    }
}
