// OrderService — typed wrapper over APIClient for the Whisked endpoints.
// Single place that names the response types so handlers and stores stay
// free of `.request(_, as: WhiskedOrderResponse.self)` ceremony.
import Foundation

@MainActor
final class OrderService {

    /// `APIClient` is an actor with a private init, so the only public
    /// instance is `APIClient.shared`. The default argument lets tests inject
    /// a stub by constructing `OrderService(client: stub)` while production
    /// code calls `OrderService()`.
    private let client: APIClient

    init(client: APIClient = APIClient.shared) {
        self.client = client
    }

    /// GET /api/whisked/menu — public read, no auth required.
    func fetchMenu() async throws -> [WhiskedMenuItemRow] {
        try await client.request(.whiskedMenu, as: [WhiskedMenuItemRow].self)
    }

    /// POST /api/whisked/orders — places a new order. Returns the order with
    /// its freshly-minted pickup code; `stripeClientSecret` is populated
    /// here and only here (cached locally by the caller).
    func placeOrder(
        businessId: Int,
        items:      [OrderItemRequest]
    ) async throws -> WhiskedOrderResponse {
        let body = PlaceOrderRequest(businessId: businessId, items: items)
        return try await client.request(
            try .whiskedPlaceOrder(body),
            as: WhiskedOrderResponse.self
        )
    }

    /// GET /api/whisked/orders/:id — refreshes the in-flight order. The
    /// status field advances `pending → preparing → ready → collected`.
    func getOrder(id: Int) async throws -> WhiskedOrderResponse {
        try await client.request(.whiskedOrder(id: id), as: WhiskedOrderResponse.self)
    }
}
