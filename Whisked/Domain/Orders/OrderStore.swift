// OrderStore — source of truth for menu, cart, and the customer's
// in-flight order. Owned by the root environment for the lifetime of the
// session — never recreated.
//
// Errors land in `error` as a human-readable String; views render it
// directly. `isLoading` and `isPlacing` gate the spinner / disabled-button
// states.
import Foundation
import Observation

@Observable
@MainActor
final class OrderStore {

    var menu:         [WhiskedMenuItemRow] = []
    var cart:         [CartItem] = []
    var currentOrder: WhiskedOrderResponse? = nil
    var isLoading    = false
    var isPlacing    = false
    var error:       String? = nil

    private let service: OrderService

    init(service: OrderService = OrderService()) {
        self.service = service
    }

    /// Sum of all line totals, in cents. Views render
    /// `Decimal(store.cartTotalCents) / 100` formatted as CAD.
    var cartTotalCents: Int {
        cart.reduce(0) { $0 + ($1.priceCents * $1.quantity) }
    }

    // MARK: - Menu

    /// GET /api/whisked/menu. Idempotent — re-fetching replaces the cached
    /// list so menu edits on the server propagate without an app restart.
    func fetchMenu() async {
        isLoading = true
        defer { isLoading = false }
        do {
            menu  = try await service.fetchMenu()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Cart

    func addToCart(_ item: WhiskedMenuItemRow) {
        if let idx = cart.firstIndex(where: { $0.menuItemId == item.id }) {
            cart[idx].quantity += 1
        } else {
            cart.append(CartItem(
                menuItemId: item.id,
                name:       item.name,
                priceCents: item.priceCents,
                quantity:   1
            ))
        }
    }

    func removeFromCart(_ item: CartItem) {
        cart.removeAll { $0.id == item.id }
    }

    func clearCart() { cart.removeAll() }

    // MARK: - Place / refresh

    /// POST /api/whisked/orders. Clears the cart on success; leaves it
    /// intact on failure so the user can retry without rebuilding.
    func placeOrder(businessId: Int) async {
        guard !cart.isEmpty, !isPlacing else { return }
        isPlacing = true
        defer { isPlacing = false }

        let items = cart.map {
            OrderItemRequest(menuItemId: $0.menuItemId, quantity: $0.quantity)
        }
        do {
            currentOrder = try await service.placeOrder(
                businessId: businessId,
                items:      items
            )
            cart  = []
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    /// GET /api/whisked/orders/:id. No-op when no order is in flight, so
    /// OrderStatusView can poll unconditionally without a guard.
    func refreshOrderStatus() async {
        guard let orderId = currentOrder?.order.id else { return }
        do {
            currentOrder = try await service.getOrder(id: orderId)
        } catch {
            // Don't surface refresh errors to `error` — they'd overwrite a
            // place-order error message that the user may still be reading.
            // The poll will simply try again on the next tick.
        }
    }
}
