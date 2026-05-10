// Box-fraise-platform Whisked endpoints. All paths sit under
// `/api/whisked/*` so the platform's HMAC middleware can skip the entire
// surface in one prefix rule (see server-side `hmac.rs`).
//
// Naming convention: `whiskedX` rather than `whisked_x` / `X` to avoid
// colliding with other product surfaces' `menu`, `order`, etc.
import Foundation

extension Endpoint {
    static var whiskedMenu: Endpoint {
        Endpoint(method: .get, path: "/api/whisked/menu", requiresAuth: false)
    }

    static func whiskedPlaceOrder(_ body: PlaceOrderRequest) throws -> Endpoint {
        Endpoint(
            method: .post,
            path:   "/api/whisked/orders",
            body:   try JSONEncoder().encode(body)
        )
    }

    static func whiskedOrder(id: Int) -> Endpoint {
        Endpoint(method: .get, path: "/api/whisked/orders/\(id)")
    }

    static func whiskedOrderPickupCode(id: Int) -> Endpoint {
        Endpoint(method: .get, path: "/api/whisked/orders/\(id)/pickup-code")
    }
}
