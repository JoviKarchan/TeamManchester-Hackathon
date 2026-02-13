import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String
    var profileImageURL: String?
    
    init(id: UUID = UUID(), name: String, email: String, profileImageURL: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
    }
}
