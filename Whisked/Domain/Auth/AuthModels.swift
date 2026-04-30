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
    /// Whether the account email has been verified.
    /// Defaults to true when absent from the API response so the banner
    /// only shows when the backend explicitly returns false.
    let verified:    Bool

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt   = "created_at"
        case verified
    }

    init(from decoder: Decoder) throws {
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(Int.self,    forKey: .id)
        email       = try c.decode(String.self, forKey: .email)
        displayName = try c.decode(String.self, forKey: .displayName)
        createdAt   = try c.decode(Date.self,   forKey: .createdAt)
        verified    = try c.decodeIfPresent(Bool.self, forKey: .verified) ?? true
    }
}
