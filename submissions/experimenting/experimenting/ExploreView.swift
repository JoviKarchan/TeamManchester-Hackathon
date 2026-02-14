import SwiftUI

struct ExploreView: View {
    @EnvironmentObject private var historyStore: HistoryStore
    @State private var recommendations: [RecommendedProduct] = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()
            
            if historyStore.items.isEmpty {
                emptyStateView
            } else if recommendations.isEmpty && !isLoading {
                emptyStateView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerView
                        
                        if isLoading {
                            loadingView
                        } else {
                            recommendationsView
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .foregroundStyle(Color("All"))
        .task {
            await loadRecommendations()
        }
        .onChange(of: historyStore.items.count) { _ in
            Task {
                await loadRecommendations()
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Explore")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color("All"))
            
            Text("Recommended for you")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("All").opacity(0.6))
        }
    }
    
    private var recommendationsView: some View {
        let screenWidth = UIScreen.main.bounds.width
     
        let cardWidth = (screenWidth - 24 - 24 - 16) / 2
        let columns = [
            GridItem(.fixed(cardWidth), spacing: 16),
            GridItem(.fixed(cardWidth), spacing: 16)
        ]
        
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
            ForEach(recommendations) { product in
                ExploreProductCard(product: product, fixedWidth: cardWidth)
            }
        }
    }
    
    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Spacer()
        }
        .padding(.vertical, 60)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundColor(Color("All").opacity(0.3))
            
            Text("Start exploring")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(Color("All"))
            
            Text("Search for items to see personalized recommendations")
                .font(.system(size: 16))
                .foregroundColor(Color("All").opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadRecommendations() async {
        guard !historyStore.items.isEmpty else {
            recommendations = []
            return
        }
        
        isLoading = true
        let newRecommendations = await ProductRecommendationService.shared.generateRecommendations(from: historyStore.items)
        
        await MainActor.run {
            recommendations = newRecommendations
            isLoading = false
        }
    }
}

struct ExploreProductCard: View {
    let product: RecommendedProduct
    let fixedWidth: CGFloat
    @State private var convertedPrice: String?
    
    // Fixed dimensions - SET IN STONE
    private let imageHeight: CGFloat = 200
    private let cardHeight: CGFloat = 320
    
    var body: some View {
        Button(action: {
            if let url = URL(string: product.link) {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if !product.imageURL.isEmpty, let imageURL = URL(string: product.imageURL) {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure, .empty:
                                    placeholderImage
                                @unknown default:
                                    placeholderImage
                                }
                            }
                        } else {
                            placeholderImage
                        }
                    }
                    .frame(width: fixedWidth - 24, height: imageHeight) // Fixed width and height
                    .clipped()
                    
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.4))
                        )
                        .padding(10)
                }
                .frame(width: fixedWidth - 24, height: imageHeight) // Fixed width and height
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("All"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(height: 36, alignment: .top)
                    
                    Text(convertedPrice ?? product.price)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color("All"))
                    
                    Text(product.source)
                        .font(.system(size: 11))
                        .foregroundColor(Color("All").opacity(0.5))
                        .lineLimit(1)
                }
                .padding(.top, 10)
                .frame(width: fixedWidth - 24, alignment: .leading) // Fixed width
            }
            .padding(12)
            .frame(width: fixedWidth, height: cardHeight) // Fixed width and height
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color("CardColor"))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
        .task {
            convertedPrice = await CurrencyConverter.shared.convertToINR(priceString: product.price)
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("CardColor"),
                    Color("CardColor").opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "photo.fill")
                .font(.system(size: 36))
                .foregroundColor(Color("All").opacity(0.15))
        }
        .frame(width: fixedWidth - 24, height: imageHeight) // Fixed width and height
        .clipped()
    }
}

#Preview {
    ExploreView()
        .environmentObject(HistoryStore())
}
