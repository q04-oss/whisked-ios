import Foundation

struct TokenPair: Decodable {
    let accessToken:  String
    let refreshToken: String
    let expiresIn:    Int

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn    = "expires_in"
    }
}

struct CustomerProfile: Decodable, Equatable {
    let id:          Int
    let email:       String
    let displayName: String
    let createdAt:   Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt   = "created_at"
    }
}
