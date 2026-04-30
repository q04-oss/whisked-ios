import Foundation

extension Endpoint {
    static var loyaltyBalance: Endpoint {
        Endpoint(method: .get, path: "/api/businesses/\(Config.businessID)/loyalty")
    }

    static func loyaltyHistory(limit: Int = 20, offset: Int = 0) -> Endpoint {
        Endpoint(
            method: .get,
            path: "/api/businesses/\(Config.businessID)/loyalty/history",
            queryItems: [
                URLQueryItem(name: "limit",  value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset)),
            ]
        )
    }

    static var qrToken: Endpoint {
        Endpoint(method: .get, path: "/api/businesses/\(Config.businessID)/loyalty/qr-token")
    }
}
