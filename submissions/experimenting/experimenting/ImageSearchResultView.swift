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
        let sortedMatches = sortMatches(matches, by: priceSortOption)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Closest match")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color("All"))
                
                Spacer()
                
                if matches.count > 1 {
                    priceFilterMenu
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sortedMatches) { match in
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
                    ForEach(0..<min(sortedMatches.count, 5), id: \.self) { index in
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
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    priceSortOption = priceSortOption == .lowToHigh ? .none : .lowToHigh
                }
            } label: {
                HStack(spacing: 6) {
                    Text("💰")
                        .font(.system(size: 16))
                    Text("Low")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(priceSortOption == .lowToHigh ? .white : Color("All"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(priceSortOption == .lowToHigh ? Color.blue : Color("CardColor"))
                )
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    priceSortOption = priceSortOption == .highToLow ? .none : .highToLow
                }
            } label: {
                HStack(spacing: 6) {
                    Text("💎")
                        .font(.system(size: 16))
                    Text("High")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(priceSortOption == .highToLow ? .white : Color("All"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(priceSortOption == .highToLow ? Color.blue : Color("CardColor"))
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private func sortMatches(_ matches: [LensMatch], by option: PriceSortOption) -> [LensMatch] {
        guard option != .none else { return matches }
        
        return matches.sorted { match1, match2 in
            let price1 = extractPrice(from: match1.priceLabel) ?? 0
            let price2 = extractPrice(from: match2.priceLabel) ?? 0
            
            switch option {
            case .lowToHigh:
                return price1 < price2
            case .highToLow:
                return price1 > price2
            case .none:
                return false
            }
        }
    }
    
    private func extractPrice(from priceLabel: String?) -> Double? {
        guard let priceLabel = priceLabel else { return nil }
        
        let cleaned = priceLabel
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter.number(from: cleaned)?.doubleValue
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
