import Foundation

/// Box-fraise-platform endpoints for the Whisked menu / order flow.
/// All paths sit under `/api/whisked/*` so the platform can scope
/// authorization to the Whisked product without colliding with the
/// loyalty / staff routes.
extension Endpoint {
    static var menu: Endpoint {
        Endpoint(method: .get, path: "/api/whisked/menu")
    }

    static func placeOrder(items: [(menuItemID: Int, quantity: Int)]) throws -> Endpoint {
        struct LineItem: Encodable {
            let menu_item_id: Int
            let quantity:     Int
        }
        struct Body: Encodable { let items: [LineItem] }
        let body = Body(items: items.map { LineItem(menu_item_id: $0.menuItemID, quantity: $0.quantity) })
        return Endpoint(
            method: .post,
            path:   "/api/whisked/orders",
            body:   try JSONEncoder().encode(body)
        )
    }

    static func order(id: Int) -> Endpoint {
        Endpoint(method: .get, path: "/api/whisked/orders/\(id)")
    }

    static func orderPickupCode(id: Int) -> Endpoint {
        Endpoint(method: .get, path: "/api/whisked/orders/\(id)/pickup-code")
    }
}
