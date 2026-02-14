import Foundation


struct LensMatch: Identifiable, Equatable {
    var id: String { link }
    let title: String
    let link: String
    let source: String
    let thumbnail: String?
    let priceLabel: String?
    var trustScore: Int? = nil
}


struct SerpApiGoogleLensResponse: Decodable {
    let visual_matches: [LensMatchPayload]?
}

struct LensMatchPayload: Decodable {
    let title: String?
    let link: String?
    let source: String?
    let thumbnail: String?
    let price: PricePayload?

    struct PricePayload: Decodable {
        let value: String?
        let currency: String?
    }

    var toLensMatch: LensMatch? {
        guard let link = link, !link.isEmpty else { return nil }
        return LensMatch(
            title: title ?? "Unknown",
            link: link,
            source: source ?? "",
            thumbnail: thumbnail,
            priceLabel: price?.value
        )
    }
}

struct GoogleShoppingResponse: Codable {
    let shopping_results: [ShoppingResult]?
}

struct ShoppingResult: Codable {
    let title: String?
    let link: String?
    let source: String?
    let price: String?
    let thumbnail: String?
}
