import SwiftUI

enum ImageSearchState: Equatable {
    case searching
    case noMatch
    case found([LensMatch])
}

enum PriceSortOption: String, CaseIterable {
    case none = "none"
    case lowToHigh = "lowToHigh"
    case highToLow = "highToLow"
    
    var displayName: String {
        switch self {
        case .none: return "Default"
        case .lowToHigh: return "Low to High"
        case .highToLow: return "High to Low"
        }
    }
    
    var emoji: String {
        switch self {
        case .none: return "🔀"
        case .lowToHigh: return "💰"
        case .highToLow: return "💎"
        }
    }
}

struct ImageSearchResultView: View {
    let image: UIImage
    let state: ImageSearchState
    var onTryAgain: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    @State private var priceSortOption: PriceSortOption = .none
    @State private var minTrustScore: Int? = nil
    @State private var sortedMatches: [LensMatch] = []

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch state {
            case .searching, .noMatch:
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, minHeight: 0)
                    .clipped()
                    .ignoresSafeArea()
                if state == .searching {
                    searchingOverlay
                } else if case .noMatch = state {
                    noMatchOverlay
                }
            case .found(let matches):
                VStack(spacing: 0) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: UIScreen.main.bounds.height * 0.55)
                        .clipped()
                    foundContent(matches: matches)
                }
                .ignoresSafeArea(edges: .top)
                .onAppear {
                    Task {
                        sortedMatches = await filterAndSortMatches(matches, priceOption: priceSortOption, minTrustScore: minTrustScore)
                    }
                }
                .onChange(of: priceSortOption) { newOption in
                    Task {
                        sortedMatches = await filterAndSortMatches(matches, priceOption: newOption, minTrustScore: minTrustScore)
                    }
                }
                .onChange(of: minTrustScore) { newScore in
                    Task {
                        sortedMatches = await filterAndSortMatches(matches, priceOption: priceSortOption, minTrustScore: newScore)
                    }
                }
            }

            backButton
        }
        .background(Color.black.ignoresSafeArea())
    }

    private var backButton: some View {
        Button {
            onDismiss?()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(.white.opacity(0.2)))
        }
        .padding(.leading, 16)
        .padding(.top, 8)
    }

    private var searchingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            Text("Searching...")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
        }
    }

    private var noMatchOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text("No matches found :(")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                Text("Try selecting a different area or take another photo")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button(action: { onTryAgain?() }) {
                    Text("Try again")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.white)
                        )
                }
                .frame(width: 200)
                .padding(.top, 24)
            }
        }
    }

    private func foundContent(matches: [LensMatch]) -> some View {
        let displayMatches = sortedMatches.isEmpty ? matches : sortedMatches
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Closest match")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color("All"))
                
                Spacer()
                
                if matches.count > 1 {
                    HStack(spacing: 8) {
                        priceFilterMenu
                        trustScoreFilterMenu
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(displayMatches) { match in
                        FoundItemCardView(match: match) {
                            if let url = URL(string: match.link) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .frame(width: 320)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
            }
            if matches.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<min(displayMatches.count, 5), id: \.self) { index in
                        Circle()
                            .fill(Color("All").opacity(index == 0 ? 0.8 : 0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("Background"))
    }
    
    private var priceFilterMenu: some View {
        Menu {
            ForEach(PriceSortOption.allCases, id: \.rawValue) { option in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        priceSortOption = option
                    }
                } label: {
                    HStack {
                        Text("\(option.emoji) \(option.displayName)")
                        if priceSortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(priceSortOption.emoji)
                    .font(.system(size: 16))
                Text(priceSortOption.displayName)
                    .font(.system(size: 14, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(priceSortOption == .none ? Color("All") : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(priceSortOption == .none ? Color("CardColor") : Color.blue)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var trustScoreFilterMenu: some View {
        Menu {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    minTrustScore = nil
                }
            } label: {
                HStack {
                    Text("All")
                    if minTrustScore == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    minTrustScore = 70
                }
            } label: {
                HStack {
                    Text("70+")
                    if minTrustScore == 70 {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    minTrustScore = 80
                }
            } label: {
                HStack {
                    Text("80+")
                    if minTrustScore == 80 {
                        Image(systemName: "checkmark")
                    }
                }
            }
            
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    minTrustScore = 90
                }
            } label: {
                HStack {
                    Text("90+")
                    if minTrustScore == 90 {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 14, weight: .semibold))
                Text(minTrustScore != nil ? "\(minTrustScore!)+" : "Trust")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(minTrustScore != nil ? .white : Color("All"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(minTrustScore != nil ? Color.gray : Color("CardColor"))
            )
        }
    }
    
    private func filterAndSortMatches(_ matches: [LensMatch], priceOption: PriceSortOption, minTrustScore: Int?) async -> [LensMatch] {
        // First filter by trust score
        var filtered = matches
        if let minScore = minTrustScore {
            filtered = matches.filter { match in
                guard let score = match.trustScore else { return false }
                return score >= minScore
            }
        }
        
        // Then sort by price if needed
        guard priceOption != .none else { return filtered }
        
        var matchesWithPrices: [(match: LensMatch, price: Double)] = []
        
        for match in filtered {
            let price = await extractPriceInINR(from: match.priceLabel) ?? 0
            matchesWithPrices.append((match: match, price: price))
        }
        
        matchesWithPrices.sort { item1, item2 in
            switch priceOption {
            case .lowToHigh:
                return item1.price < item2.price
            case .highToLow:
                return item1.price > item2.price
            case .none:
                return false
            }
        }
        
        return matchesWithPrices.map { $0.match }
    }
    
    private func sortMatches(_ matches: [LensMatch], by option: PriceSortOption) async -> [LensMatch] {
        guard option != .none else { return matches }
        
        var matchesWithPrices: [(match: LensMatch, price: Double)] = []
        
        for match in matches {
            let price = await extractPriceInINR(from: match.priceLabel) ?? 0
            matchesWithPrices.append((match: match, price: price))
        }
        
        matchesWithPrices.sort { item1, item2 in
            switch option {
            case .lowToHigh:
                return item1.price < item2.price
            case .highToLow:
                return item1.price > item2.price
            case .none:
                return false
            }
        }
        
        return matchesWithPrices.map { $0.match }
    }
    
    private func extractPriceInINR(from priceLabel: String?) async -> Double? {
        guard let priceLabel = priceLabel else { return nil }
        
        guard let (amount, currencyCode) = parsePrice(priceLabel) else {
            return nil
        }
        
        if currencyCode.uppercased() == "INR" {
            return amount
        }
        
        return await CurrencyConverter.shared.convertToINR(amount: amount, from: currencyCode)
    }
    
    private func parsePrice(_ priceString: String) -> (amount: Double, currencyCode: String)? {
        let trimmed = priceString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let currencyMap: [String: String] = [
            "$": "USD",
            "€": "EUR",
            "£": "GBP",
            "¥": "JPY",
            "₹": "INR",
            "A$": "AUD",
            "C$": "CAD",
            "CHF": "CHF",
            "CN¥": "CNY",
            "HK$": "HKD",
            "NZ$": "NZD",
            "SEK": "SEK",
            "NOK": "NOK",
            "DKK": "DKK",
            "PLN": "PLN",
            "R$": "BRL",
            "ZAR": "ZAR",
            "MXN": "MXN"
        ]
        
        var currencyCode = "USD"
        var cleaned = trimmed
        
        for (symbol, code) in currencyMap.sorted(by: { $0.key.count > $1.key.count }) {
            if trimmed.uppercased().contains(symbol.uppercased()) {
                currencyCode = code
                cleaned = cleaned.replacingOccurrences(of: symbol, with: "", options: .caseInsensitive)
                break
            }
        }
        
        cleaned = cleaned
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.").inverted)
        
        guard let amount = Double(cleaned) else {
            return nil
        }
        
        return (amount, currencyCode)
    }
}

#Preview("Searching") {
    ImageSearchResultView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        state: .searching
    )
}

#Preview("No match") {
    ImageSearchResultView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        state: .noMatch,
        onTryAgain: {}
    )
}
