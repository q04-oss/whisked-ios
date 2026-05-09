import Foundation
import Observation

/// Source of truth for the menu, the local cart, and the customer's
/// in-flight order. Owned by the root environment for the lifetime of the
/// session — never recreated.
@Observable
@MainActor
final class OrderStore {
    private(set) var menu:         [MenuItem] = []
    private(set) var cart:         [CartItem] = []
    private(set) var currentOrder: Order? = nil
    private(set) var isLoading    = false
    private(set) var isPlacing    = false
    private(set) var error:       APIError?

    private let api = APIClient.shared

    var cartTotal: Decimal {
        cart.reduce(0) { $0 + $1.lineTotal }
    }

    // MARK: - Menu

    /// Loads the menu. Stubbed until `GET /api/whisked/menu` ships on
    /// box-fraise-platform. The placeholder set is enough to render the
    /// Menu / Cart / Order flow end-to-end.
    func fetchMenu() async {
        guard menu.isEmpty else { return }
        menu = MenuItem.placeholders
    }

    // MARK: - Cart

    func addToCart(_ item: MenuItem) {
        if let idx = cart.firstIndex(where: { $0.menuItem.id == item.id }) {
            cart[idx].quantity += 1
        } else {
            cart.append(CartItem(id: UUID(), menuItem: item, quantity: 1))
        }
    }

    func removeFromCart(_ cartItem: CartItem) {
        cart.removeAll { $0.id == cartItem.id }
    }

    func clearCart() { cart.removeAll() }

    // MARK: - Place / refresh

    /// Stub: builds a synthetic pending order so OrderStatusView has
    /// something to render. The real implementation will
    /// `POST /api/whisked/orders` and decode the server's `Order`.
    func placeOrder() async {
        guard !cart.isEmpty, !isPlacing else { return }
        isPlacing = true
        defer { isPlacing = false }

        currentOrder = Order(
            id:         Int.random(in: 1000...9999),
            status:     .pending,
            pickupCode: nil,
            totalCents: NSDecimalNumber(decimal: cartTotal * 100).intValue,
            createdAt:  Date(),
            items:      []
        )
        clearCart()
    }

    /// Stub: real implementation will `GET /api/whisked/orders/:id` and
    /// replace `currentOrder` with the freshly decoded value. Called on
    /// scenePhase → .active and on `.orderDidUpdate` push notifications.
    func refreshOrderStatus() async {
        guard currentOrder != nil else { return }
        // No-op for now — endpoint not yet implemented server-side.
    }
}

// MARK: - Placeholder menu (stub until /api/whisked/menu lands)

private extension MenuItem {
    static let placeholders: [MenuItem] = [
        MenuItem(id: 1, name: "Matcha Latte",         description: "Ceremonial-grade matcha, oat milk",   priceCents: 750),
        MenuItem(id: 2, name: "Vanilla Honey Matcha", description: "Bourbon vanilla, raw honey",          priceCents: 850),
        MenuItem(id: 3, name: "Hojicha Latte",        description: "Roasted green tea, oat milk",         priceCents: 750),
        MenuItem(id: 4, name: "Iced Matcha Tonic",    description: "Single-origin matcha over tonic",     priceCents: 850),
    ]
}
