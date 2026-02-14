import Foundation


enum SerpApiClient {
    private static let apiKey = "40044111f285e974493aa02442a4c2131285b6ef7020baaa50ca9378acf0ec39"
    private static let baseURL = "https://serpapi.com/search.json"

    static func searchWithImageURL(_ imageURL: URL) async throws -> LensMatch? {
        let all = try await searchWithImageURLAllMatches(imageURL)
        return all.first
    }

    static func searchWithImageURLAllMatches(_ imageURL: URL) async throws -> [LensMatch] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "engine", value: "google_lens"),
            URLQueryItem(name: "url", value: imageURL.absoluteString),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "type", value: "visual_matches"),
        ]
        guard let url = components.url else {
            throw SerpApiError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw SerpApiError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw SerpApiError.serverError(statusCode: http.statusCode, body: body)
        }

        let decoded = try JSONDecoder().decode(SerpApiGoogleLensResponse.self, from: data)
        let matches = decoded.visual_matches?.lazy.compactMap(\.toLensMatch) ?? []
        return Array(matches)
    }
    
    static func searchShopping(query: String) async throws -> [LensMatch] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "engine", value: "google_shopping"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "num", value: "20"),
        ]
        guard let url = components.url else {
            throw SerpApiError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw SerpApiError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw SerpApiError.serverError(statusCode: http.statusCode, body: body)
        }

        let decoded = try JSONDecoder().decode(GoogleShoppingResponse.self, from: data)
        let matches = decoded.shopping_results?.compactMap { result -> LensMatch? in
            guard let link = result.link,
                  let title = result.title else { return nil }
            return LensMatch(
                title: title,
                link: link,
                source: result.source ?? "Unknown",
                thumbnail: result.thumbnail,
                priceLabel: result.price
            )
        } ?? []
        return matches
    }
}

enum SerpApiError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, body: String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid SerpAPI URL."
        case .invalidResponse: return "Invalid response."
        case .serverError(let code, let body): return "SerpAPI error (\(code)): \(body ?? "no body")"
        }
    }
}
