import Foundation

struct TrustScoreResponse: Decodable {
    let trustScore: Int?
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case trustScore = "trust_score"
        case trustScoreAlt = "trustScore"
        case score
        case status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try different possible field names for trust score
        if let score = try? container.decodeIfPresent(Int.self, forKey: .trustScore) {
            self.trustScore = score
        } else if let score = try? container.decodeIfPresent(Int.self, forKey: .trustScoreAlt) {
            self.trustScore = score
        } else if let score = try? container.decodeIfPresent(Int.self, forKey: .score) {
            self.trustScore = score
        } else {
            self.trustScore = nil
        }
        
        self.status = try? container.decodeIfPresent(String.self, forKey: .status)
    }
}

enum TrustScoreClient {
    private static let apiKey = "681d3c840cmsh9619c1f15e601dbp1881f7jsne01e3a082317"
    private static let baseURL = "https://scamadviser-lite.p.rapidapi.com/v1/trust/single"
    
    /// Extracts base domain from a URL string
    /// Example: "https://www.amazon.com/path/to/item" -> "amazon.com"
    static func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        // Get host (e.g., "www.amazon.com")
        guard let host = url.host else { return nil }
        
        // Remove "www." prefix if present
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        
        return domain
    }
    
    /// Fetches trust score for a domain
    static func getTrustScore(for domain: String) async throws -> Int? {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "domain", value: domain),
            URLQueryItem(name: "refresh", value: "false")
        ]
        
        guard let url = components.url else {
            throw TrustScoreError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.setValue("scamadviser-lite.p.rapidapi.com", forHTTPHeaderField: "x-rapidapi-host")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("no-cache", forHTTPHeaderField: "cache-control")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw TrustScoreError.invalidResponse
        }
        
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8)
            throw TrustScoreError.serverError(statusCode: http.statusCode, body: body)
        }
        
        let decoded = try JSONDecoder().decode(TrustScoreResponse.self, from: data)
        return decoded.trustScore
    }
    
    /// Fetches trust score from a URL string (extracts domain automatically)
    static func getTrustScore(from urlString: String) async throws -> Int? {
        guard let domain = extractDomain(from: urlString) else {
            return nil
        }
        return try await getTrustScore(for: domain)
    }
}

enum TrustScoreError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, body: String?)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid trust score URL."
        case .invalidResponse: return "Invalid response."
        case .serverError(let code, let body): return "Trust score error (\(code)): \(body ?? "no body")"
        }
    }
}
