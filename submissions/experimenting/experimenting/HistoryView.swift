import SwiftUI


struct HistoryItem: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let date: Date
    let imageURL: URL

    init(id: UUID = UUID(), title: String, date: Date, imageURL: URL) {
        self.id = id
        self.title = title
        self.date = date
        self.imageURL = imageURL
    }

   
    static func dateText(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Today, \(timeString(date))"
        } else if cal.isDateInYesterday(date) {
            return "Yesterday, \(timeString(date))"
        } else {
            let df = DateFormatter()
            df.dateFormat = "d MMMM yyyy"
            return df.string(from: date)
        }
    }
    private static func timeString(_ date: Date) -> String {
        let tf = DateFormatter()
        tf.dateFormat = "H:mm"
        return tf.string(from: date)
    }
}


struct HistoryView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @State private var query = ""
    @FocusState private var isSearchFocused: Bool
    @State private var isSelectionMode = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showDeleteConfirmation = false

    private var items: [HistoryItem] { historyStore.items }

    var filteredItems: [HistoryItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return items }
        return items.filter { item in
            item.title.lowercased().contains(q) ||
            HistoryItem.dateText(for: item.date).lowercased().contains(q) ||
            monthSectionTitle(for: item.date).lowercased().contains(q)
        }
    }

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()

            VStack(spacing: 0) {
                // Title (centered)
                Text("History")
                    .font(.system(size: 20, weight: .semibold))
                    .padding(.top, 36)
                    .padding(.bottom, 10)

                HStack(alignment: .lastTextBaseline) {
                    if isSelectionMode {
                        Text("\(selectedIDs.count) Selected")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.top, 22)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 25)
                        Button("Cancel") {
                            isSelectionMode = false
                            selectedIDs = []
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 17, weight: .regular))
                        .padding(.trailing, 25)
                        .padding(.top, 22)
                    } else {
                        Text("\(items.count) items")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.top, 22)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 25)
                        Button("Select") {
                            isSelectionMode = true
                        }
                        .foregroundColor(Color("All").opacity(0.6))
                        .font(.system(size: 17, weight: .regular))
                        .padding(.trailing, 25)
                        .padding(.top, 22)
                    }
                }


                     
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color("All").opacity(0.55))

                        TextField("Name, date or type", text: $query)
                            .focused($isSearchFocused)
                            .submitLabel(.search)
                            .foregroundColor(Color("All"))

                        if !query.isEmpty {
                            Button {
                                query = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color("All").opacity(0.35))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.black.opacity(0.06))
                    )

                    if isSearchFocused || !query.isEmpty {
                        Button("Cancel") {
                            query = ""
                            isSearchFocused = false
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 17, weight: .regular))
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .padding(.top)
                

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(sectioned(filteredItems), id: \.title) { section in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(section.title)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(Color("All").opacity(0.85))
                                    .padding(.horizontal, 20)

                                VStack(spacing: 12) {
                                    ForEach(section.items) { item in
                                        HistoryPillRow(
                                            imageURL: item.imageURL,
                                            title: item.title,
                                            subtitle: HistoryItem.dateText(for: item.date),
                                            isSelectionMode: isSelectionMode,
                                            isSelected: selectedIDs.contains(item.id)
                                        ) {
                                            if isSelectionMode {
                                                if selectedIDs.contains(item.id) {
                                                    selectedIDs.remove(item.id)
                                                } else {
                                                    selectedIDs.insert(item.id)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 90)
                    }
                    .padding(.top, 6)
                    
                }
            }

            if isSelectionMode {
                VStack {
                    Spacer()
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                    .disabled(selectedIDs.isEmpty)
                    .opacity(selectedIDs.isEmpty ? 0.5 : 1)
                }
                .allowsHitTesting(true)
            }
        }
        .foregroundStyle(Color("All"))
        .animation(.easeOut(duration: 0.15), value: isSearchFocused)
        .animation(.easeOut(duration: 0.2), value: isSelectionMode)
        .animation(.easeOut(duration: 0.2), value: selectedIDs.count)
        .confirmationDialog("Delete \(selectedIDs.count) item\(selectedIDs.count == 1 ? "" : "s")?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Cancel", role: .cancel) {
                showDeleteConfirmation = false
            }
            Button("Delete", role: .destructive) {
                historyStore.remove(ids: selectedIDs)
                selectedIDs = []
                isSelectionMode = false
                showDeleteConfirmation = false
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct HistoryPillRow: View {
    let imageURL: URL
    let title: String
    let subtitle: String
    var isSelectionMode: Bool = false
    var isSelected: Bool = false
    var onTap: (() -> Void)?

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color(.systemGray5)
                    }
                }
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("All"))

                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color("All").opacity(0.55))
                }

                Spacer()

                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .blue : Color("All").opacity(0.35))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("All").opacity(0.35))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color("CardColor"))
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

private extension HistoryView {
    struct SectionGroup: Hashable {
        let title: String
        let items: [HistoryItem]
    }

    func sectioned(_ items: [HistoryItem]) -> [SectionGroup] {
        let cal = Calendar.current

        var today: [HistoryItem] = []
        var yesterday: [HistoryItem] = []
        var monthBuckets: [String: [HistoryItem]] = [:]

        for item in items.sorted(by: { $0.date > $1.date }) {
            if cal.isDateInToday(item.date) {
                today.append(item)
            } else if cal.isDateInYesterday(item.date) {
                yesterday.append(item)
            } else {
                let key = monthSectionTitle(for: item.date)
                monthBuckets[key, default: []].append(item)
            }
        }

        var result: [SectionGroup] = []
        if !today.isEmpty { result.append(.init(title: "Today", items: today)) }
        if !yesterday.isEmpty { result.append(.init(title: "Yesterday", items: yesterday)) }

    
        let sortedMonths = monthBuckets.keys.sorted { a, b in
            // parse month titles back into dates for ordering
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.dateFormat = "MMMM yyyy"
            return (fmt.date(from: a) ?? .distantPast) > (fmt.date(from: b) ?? .distantPast)
        }

        for m in sortedMonths {
            if let bucket = monthBuckets[m] {
                result.append(.init(title: m, items: bucket))
            }
        }

        return result
    }

    func monthSectionTitle(for date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.string(from: date)
    }

}

#Preview {
    HistoryView()
        .environmentObject(HistoryStore())
}
