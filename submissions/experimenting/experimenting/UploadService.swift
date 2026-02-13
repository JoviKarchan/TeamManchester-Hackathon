import Foundation
import UIKit


enum UploadService {
    private static let imgbbKey = "4d0c22766b5e53dbcf8c96de6ece10e1"
    private static let uploadURL = URL(string: "https://api.imgbb.com/1/upload")!

    
    static func uploadImage(_ image: UIImage) async throws -> URL {
        guard let jpegData = image.jpegData(compressionQuality: 0.8) else {
            throw UploadError.compressionFailed
        }
        let base64 = jpegData.base64EncodedString()
        return try await uploadBase64(base64)
    }


    static func uploadBase64(_ base64: String) async throws -> URL {
        var components = URLComponents(url: uploadURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: imgbbKey)]
        guard let requestURL = components.url else { throw UploadError.invalidURL }

       
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_.~"))
        let encoded = base64.addingPercentEncoding(withAllowedCharacters: allowed) ?? base64

        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "image=\(encoded)".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw UploadError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            throw UploadError.serverError(statusCode: http.statusCode, body: String(data: data, encoding: .utf8))
        }

        let decoded = try JSONDecoder().decode(ImgBBResponse.self, from: data)
        guard let url = decoded.data?.url.flatMap(URL.init(string:)) else {
            throw UploadError.missingURL
        }
        return url
    }
}


private struct ImgBBResponse: Decodable {
    let data: ImgBBData?
}

private struct ImgBBData: Decodable {
    let url: String?
}


enum UploadError: LocalizedError {
    case compressionFailed
    case invalidURL
    case invalidResponse
    case missingURL
    case serverError(statusCode: Int, body: String?)

    var errorDescription: String? {
        switch self {
        case .compressionFailed: return "Failed to compress image."
        case .invalidURL: return "Invalid upload URL."
        case .invalidResponse: return "Invalid response."
        case .missingURL: return "ImgBB response did not contain image URL."
        case .serverError(let code, let body): return "Upload failed (\(code)): \(body ?? "no body")"
        }
    }
}
