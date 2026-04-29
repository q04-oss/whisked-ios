import Foundation

extension Endpoint {
    static var loyaltyBalance: Endpoint {
        Endpoint(method: .get, path: "/v1/loyalty/balance")
    }

    static func loyaltyHistory(limit: Int = 20, offset: Int = 0) -> Endpoint {
        Endpoint(
            method: .get,
            path: "/v1/loyalty/history",
            queryItems: [
                URLQueryItem(name: "limit",  value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset)),
            ]
        )
    }

    static func stamp(locationID: Int? = nil, idempotencyKey: String) throws -> Endpoint {
        struct Body: Encodable {
            let location_id: Int?
            let idempotency_key: String
        }
        return Endpoint(
            method: .post,
            path: "/v1/loyalty/stamp",
            body: try JSONEncoder().encode(Body(location_id: locationID, idempotency_key: idempotencyKey))
        )
    }

    static var redeem: Endpoint {
        Endpoint(method: .post, path: "/v1/loyalty/redeem", body: Data("{}".utf8))
    }
}
