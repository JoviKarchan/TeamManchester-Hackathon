import Combine
import Foundation
import SwiftUI


final class HistoryStore: ObservableObject {
    @Published private(set) var items: [HistoryItem] = []
    private let key = "findly.searchHistory"
    private let maxItems = 100

    init() {
        load()
    }

    func add(title: String, date: Date, imageURL: URL) {
        let item = HistoryItem(title: title, date: date, imageURL: imageURL)
        items.insert(item, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        save()
    }

    func remove(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        items.removeAll { ids.contains($0.id) }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
