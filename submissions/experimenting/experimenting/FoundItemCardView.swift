import SwiftUI


struct FoundItemCardView: View {
    let match: LensMatch
    var onTap: (() -> Void)?
    @State private var convertedPrice: String?

    var body: some View {
        Button(action: { onTap?() }) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 14) {
                    thumbnailView
                    VStack(alignment: .leading, spacing: 6) {
                        Text(match.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color("All"))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(match.source)
                            .font(.system(size: 14))
                            .foregroundColor(Color("All").opacity(0.7))
                        if let price = convertedPrice ?? match.priceLabel {
                            Text(price)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color("All"))
                        }
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("All").opacity(0.7))
                }
                .padding(16)
                
                if let trustScore = match.trustScore {
                    trustScoreIndicator(score: trustScore)
                        .padding(.top, 12)
                        .padding(.trailing, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color("CardColor"))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            )
        }
        .buttonStyle(.plain)
        .task {
            if let priceLabel = match.priceLabel {
                convertedPrice = await CurrencyConverter.shared.convertToINR(priceString: priceLabel)
            }
        }
    }
    
    private func trustScoreIndicator(score: Int) -> some View {
        let clampedScore = max(0, min(100, score))
        let progress = Double(clampedScore) / 100.0
        
        return ZStack {
            // Background circle (light grey)
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 2.5)
                .frame(width: 36, height: 36)
            
            // Filled progress circle (dark grey)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.gray.opacity(0.7), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(-90))
            
            // Score text
            Text("\(clampedScore)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.gray.opacity(0.8))
        }
    }

    private var thumbnailView: some View {
        Group {
            if let urlString = match.thumbnail, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Color(.systemGray5)
                            .overlay { Image(systemName: "photo").foregroundColor(.gray) }
                    }
                }
            } else {
                Color(.systemGray5)
                    .overlay { Image(systemName: "photo").foregroundColor(.gray) }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    FoundItemCardView(
        match: LensMatch(
            title: "Soft Knit Ribbed Cardigan",
            link: "https://example.com",
            source: "Milo Studio",
            thumbnail: nil,
            priceLabel: "$19.99"
        )
    )
    .padding()
}
