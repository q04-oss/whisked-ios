import Foundation

struct AuthResponse: Decodable {
    let token:    String
    let isNew:    Bool
    let verified: Bool

    enum CodingKeys: String, CodingKey {
        case token
        case isNew    = "is_new"
        case verified
    }
}

struct CustomerProfile: Decodable, Equatable {
    let id:          Int
    let email:       String
    let displayName: String?
    let verified:    Bool

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case verified
    }

    init(from decoder: Decoder) throws {
        let c       = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(Int.self,    forKey: .id)
        email       = try c.decode(String.self, forKey: .email)
        displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
        verified    = try c.decodeIfPresent(Bool.self,   forKey: .verified) ?? true
    }
}
