import Foundation

struct RecommendedProduct: Identifiable {
    let id: String
    let title: String
    let price: String
    let imageURL: String
    let link: String
    let source: String
}

struct StyleProfile {
    var categories: Set<String>
    var styles: Set<String>
    var colors: Set<String>
    var brands: Set<String>
    var keywords: [String]
}

class ProductRecommendationService {
    static let shared = ProductRecommendationService()
    
    private init() {}
    
    func generateRecommendations(from historyItems: [HistoryItem]) async -> [RecommendedProduct] {
        guard !historyItems.isEmpty else { return [] }
        
        let profile = analyzeStyleProfile(from: historyItems)
        var allRecommendations: [RecommendedProduct] = []
        
        let hasFitnessInterest = profile.categories.contains("watches") || 
                                 historyItems.contains { item in
                                     let title = item.title.lowercased()
                                     return title.contains("whoop") || title.contains("fitness") || 
                                            title.contains("tracker") || title.contains("watch") || 
                                            title.contains("band")
                                 }
        
        if hasFitnessInterest {
            let stockProducts = getStockFitnessProducts()
            allRecommendations.append(contentsOf: stockProducts)
        }
        
        for category in profile.categories {
            let query = buildSmartQuery(category: category, profile: profile)
            
            if let products = await fetchProducts(query: query) {
                allRecommendations.append(contentsOf: products)
            }
        }
        
        var seenIDs: Set<String> = []
        var uniqueProducts: [RecommendedProduct] = []
        
        for product in allRecommendations {
            if !seenIDs.contains(product.id) {
                seenIDs.insert(product.id)
                uniqueProducts.append(product)
            }
        }
        
        return Array(uniqueProducts.prefix(30))
    }
    
    private func analyzeStyleProfile(from items: [HistoryItem]) -> StyleProfile {
        var categories: Set<String> = []
        var styles: Set<String> = []
        var colors: Set<String> = []
        var brands: Set<String> = []
        var allKeywords: [String] = []
        
        for item in items {
            let title = item.title.lowercased()
            
            let category = detectCategory(title)
            categories.insert(category)
            
            let detectedStyle = detectStyle(title)
            styles.formUnion(detectedStyle)
            
            let detectedColors = detectColors(title)
            colors.formUnion(detectedColors)
            
            let detectedBrands = detectBrands(title)
            brands.formUnion(detectedBrands)
            
            let keywords = extractRelevantKeywords(title)
            allKeywords.append(contentsOf: keywords)
        }
        
        let topKeywords = Array(Set(allKeywords))
            .sorted { keyword1, keyword2 in
                allKeywords.filter { $0 == keyword1 }.count > allKeywords.filter { $0 == keyword2 }.count
            }
            .prefix(10)
        
        return StyleProfile(
            categories: categories,
            styles: styles,
            colors: colors,
            brands: brands,
            keywords: Array(topKeywords)
        )
    }
    
    private func detectCategory(_ title: String) -> String {
        let lowercased = title.lowercased()
        
        if lowercased.contains("shirt") || lowercased.contains("top") || lowercased.contains("blouse") || lowercased.contains("tee") || lowercased.contains("t-shirt") || lowercased.contains("tank") {
            return "tops"
        }
        
        if lowercased.contains("pants") || lowercased.contains("jeans") || lowercased.contains("trousers") || lowercased.contains("leggings") || lowercased.contains("chinos") {
            return "bottoms"
        }
        
        if lowercased.contains("dress") || lowercased.contains("gown") || lowercased.contains("jumpsuit") {
            return "dresses"
        }
        
        if lowercased.contains("shoes") || lowercased.contains("sneakers") || lowercased.contains("boots") || lowercased.contains("heels") || lowercased.contains("sandals") || lowercased.contains("flats") {
            return "shoes"
        }
        
        if lowercased.contains("jacket") || lowercased.contains("coat") || lowercased.contains("hoodie") || lowercased.contains("sweater") || lowercased.contains("cardigan") || lowercased.contains("blazer") {
            return "outerwear"
        }
        
        if lowercased.contains("bag") || lowercased.contains("backpack") || lowercased.contains("purse") || lowercased.contains("handbag") || lowercased.contains("tote") {
            return "bags"
        }
        
        if lowercased.contains("jewelry") || lowercased.contains("necklace") || lowercased.contains("ring") || lowercased.contains("bracelet") || lowercased.contains("earrings") {
            return "accessories"
        }
        
        if lowercased.contains("watch") || lowercased.contains("band") || lowercased.contains("fitness") || lowercased.contains("tracker") {
            return "watches"
        }
        
        return "clothing"
    }
    
    private func detectStyle(_ title: String) -> Set<String> {
        let lowercased = title.lowercased()
        var styles: Set<String> = []
        
        if lowercased.contains("vintage") || lowercased.contains("retro") || lowercased.contains("classic") {
            styles.insert("vintage")
        }
        
        if lowercased.contains("casual") || lowercased.contains("everyday") {
            styles.insert("casual")
        }
        
        if lowercased.contains("formal") || lowercased.contains("suit") || lowercased.contains("business") {
            styles.insert("formal")
        }
        
        if lowercased.contains("sport") || lowercased.contains("athletic") || lowercased.contains("active") || lowercased.contains("gym") {
            styles.insert("sporty")
        }
        
        if lowercased.contains("minimal") || lowercased.contains("simple") || lowercased.contains("basic") {
            styles.insert("minimalist")
        }
        
        if lowercased.contains("designer") || lowercased.contains("luxury") || lowercased.contains("premium") {
            styles.insert("luxury")
        }
        
        if lowercased.contains("street") || lowercased.contains("urban") || lowercased.contains("hip") {
            styles.insert("streetwear")
        }
        
        return styles
    }
    
    private func detectColors(_ title: String) -> Set<String> {
        let lowercased = title.lowercased()
        var colors: Set<String> = []
        
        let colorKeywords = ["black", "white", "gray", "grey", "navy", "blue", "red", "green", "yellow", "pink", "purple", "orange", "brown", "beige", "tan", "cream", "ivory", "maroon", "burgundy", "khaki", "olive", "coral", "teal", "turquoise"]
        
        for color in colorKeywords {
            if lowercased.contains(color) {
                colors.insert(color)
            }
        }
        
        return colors
    }
    
    private func detectBrands(_ title: String) -> Set<String> {
        let lowercased = title.lowercased()
        var brands: Set<String> = []
        
        let brandKeywords = ["nike", "adidas", "zara", "h&m", "hm", "gucci", "prada", "versace", "calvin", "ralph", "tommy", "levi", "gap", "uniqlo", "forever", "shein", "asos", "boohoo", "prettylittlething"]
        
        for brand in brandKeywords {
            if lowercased.contains(brand) {
                brands.insert(brand)
            }
        }
        
        return brands
    }
    
    private func extractRelevantKeywords(_ title: String) -> [String] {
        let separatorSet = CharacterSet.whitespaces.union(.punctuationCharacters)
        let words = title.components(separatedBy: separatorSet)
            .filter { $0.count > 3 }
            .filter { !stopWords.contains($0) }
            .filter { !colorKeywords.contains($0) }
        
        return words
    }
    
    private func buildSmartQuery(category: String, profile: StyleProfile) -> String {
        var queryParts: [String] = []
        
        if !profile.styles.isEmpty {
            queryParts.append(profile.styles.joined(separator: " "))
        }
        
        if !profile.colors.isEmpty && profile.colors.count <= 2 {
            queryParts.append(profile.colors.joined(separator: " "))
        }
        
        if !profile.keywords.isEmpty {
            queryParts.append(contentsOf: Array(profile.keywords.prefix(2)))
        }
        
        queryParts.append(category)
        
        return queryParts.joined(separator: " ")
    }
    
    private func fetchProducts(query: String) async -> [RecommendedProduct]? {
        do {
            let matches = try await SerpApiClient.searchShopping(query: query)
            
            let productsWithPrices = matches.filter { $0.priceLabel != nil && !$0.priceLabel!.isEmpty }
            
            var results = productsWithPrices.prefix(15).map { match in
                RecommendedProduct(
                    id: match.link,
                    title: match.title,
                    price: match.priceLabel ?? "Price unavailable",
                    imageURL: match.thumbnail ?? "",
                    link: match.link,
                    source: match.source
                )
            }
            
            if results.isEmpty || query.lowercased().contains("watch") || query.lowercased().contains("fitness") || query.lowercased().contains("tracker") || query.lowercased().contains("band") {
                let stockProducts = getStockFitnessProducts()
                results.append(contentsOf: stockProducts)
            }
            
            return Array(results)
        } catch {
            let stockProducts = getStockFitnessProducts()
            return stockProducts
        }
    }
    
    private func getStockFitnessProducts() -> [RecommendedProduct] {
        return [
            RecommendedProduct(
                id: "stock-1",
                title: "WHOOP 4.0 Fitness Tracker",
                price: "$239.00",
                imageURL: "https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=400&h=400&fit=crop",
                link: "https://www.whoop.com",
                source: "WHOOP"
            ),
            RecommendedProduct(
                id: "stock-2",
                title: "Apple Watch Series 9",
                price: "$399.00",
                imageURL: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop",
                link: "https://www.apple.com/apple-watch-series-9",
                source: "Apple"
            ),
            RecommendedProduct(
                id: "stock-3",
                title: "Fitbit Charge 6 Fitness Tracker",
                price: "$159.95",
                imageURL: "https://images.unsplash.com/photo-1544966503-7cc5ac882d5f?w=400&h=400&fit=crop",
                link: "https://www.fitbit.com",
                source: "Fitbit"
            ),
            RecommendedProduct(
                id: "stock-4",
                title: "Garmin Forerunner 265",
                price: "$449.99",
                imageURL: "https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?w=400&h=400&fit=crop",
                link: "https://www.garmin.com",
                source: "Garmin"
            ),
            RecommendedProduct(
                id: "stock-5",
                title: "Samsung Galaxy Watch 6",
                price: "$299.99",
                imageURL: "https://images.unsplash.com/photo-1523362628745-0c100150b504?w=400&h=400&fit=crop",
                link: "https://www.samsung.com",
                source: "Samsung"
            ),
            RecommendedProduct(
                id: "stock-6",
                title: "Oura Ring Gen 3",
                price: "$299.00",
                imageURL: "https://images.unsplash.com/photo-1611591437281-460bfbe1220a?w=400&h=400&fit=crop",
                link: "https://ouraring.com",
                source: "Oura"
            ),
            RecommendedProduct(
                id: "stock-7",
                title: "Polar Vantage V3",
                price: "$599.95",
                imageURL: "https://images.unsplash.com/photo-1579586337278-3befd40fd17a?w=400&h=400&fit=crop",
                link: "https://www.polar.com",
                source: "Polar"
            ),
            RecommendedProduct(
                id: "stock-8",
                title: "Amazfit GTR 4",
                price: "$199.99",
                imageURL: "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop",
                link: "https://www.amazfit.com",
                source: "Amazfit"
            ),
            RecommendedProduct(
                id: "stock-9",
                title: "Suunto 9 Peak Pro",
                price: "$549.00",
                imageURL: "https://images.unsplash.com/photo-1575311373937-040b8e1fd5b6?w=400&h=400&fit=crop",
                link: "https://www.suunto.com",
                source: "Suunto"
            ),
            RecommendedProduct(
                id: "stock-10",
                title: "Xiaomi Mi Band 8",
                price: "$49.99",
                imageURL: "https://images.unsplash.com/photo-1544966503-7cc5ac882d5f?w=400&h=400&fit=crop",
                link: "https://www.mi.com",
                source: "Xiaomi"
            )
        ]
    }
    
    private let stopWords = Set(["the", "and", "for", "are", "but", "not", "you", "all", "can", "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", "how", "its", "may", "new", "now", "old", "see", "two", "way", "who", "boy", "did", "its", "let", "put", "say", "she", "too", "use"])
    
    private let colorKeywords = Set(["black", "white", "gray", "grey", "navy", "blue", "red", "green", "yellow", "pink", "purple", "orange", "brown", "beige", "tan", "cream", "ivory", "maroon", "burgundy", "khaki", "olive", "coral", "teal", "turquoise"])
}
