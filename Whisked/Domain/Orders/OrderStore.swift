// OrderStore — source of truth for menu, cart, the customer's in-flight
// order, and the Stripe PaymentSheet state machine. Owned by the root
// environment for the lifetime of the session — never recreated.
//
// Payment lifecycle:
//   placeOrder() → POST /api/whisked/orders returns a `stripeClientSecret`
//   → preparePaymentSheet(clientSecret:) constructs a Stripe `PaymentSheet`
//   and flips `awaitingPayment = true` → CartView's `.paymentSheet`
//   modifier observes that flag and presents the sheet → on dismissal,
//   handlePaymentResult(_:) decides whether to keep `currentOrder` (paid)
//   or drop it (cancelled / failed) so the Order tab reflects reality.
//
// Errors land in `error` as a human-readable String; views render it
// directly. `isLoading`, `isPlacing`, and `awaitingPayment` gate the
// spinner / disabled-button / modal-sheet states.
//
// Requires the StripePaymentSheet SPM dependency — added via Xcode.
import Foundation
import Observation
import StripePaymentSheet

@Observable
@MainActor
final class OrderStore {

    var menu:         [WhiskedMenuItemRow] = []
    var cart:         [CartItem] = []
    var currentOrder: WhiskedOrderResponse? = nil
    var isLoading    = false
    var isPlacing    = false
    var error:       String? = nil

    // MARK: - Payment state

    /// Constructed by `preparePaymentSheet`. Lives until the sheet is
    /// dismissed via `handlePaymentResult`. CartView force-unwraps this
    /// when `awaitingPayment == true`; the invariant holds because both
    /// are set together.
    var paymentSheet:     PaymentSheet? = nil
    /// Last terminal result from a presented PaymentSheet. Drives the
    /// "auto-open Order tab on .completed" transition in CartView.
    var paymentResult:    PaymentSheetResult? = nil
    /// Modal-sheet presentation flag for `View.paymentSheet(isPresented:…)`.
    var awaitingPayment = false

    private let service: OrderService

    init(service: OrderService = OrderService()) {
        self.service = service
    }

    /// Sum of all line totals, in cents. Views render
    /// `Decimal(store.cartTotalCents) / 100` formatted as CAD.
    var cartTotalCents: Int {
        cart.reduce(0) { $0 + ($1.priceCents * $1.quantity) }
    }

    /// `PaymentSheetResult` doesn't conform to `Equatable`, which would
    /// otherwise let SwiftUI `.onChange` listen on `paymentResult`
    /// directly. Boolean projection keeps the change-detection simple.
    var paymentCompleted: Bool {
        if case .completed = paymentResult { return true }
        return false
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

    /// POST /api/whisked/orders. On success, clears the cart and (if the
    /// server returned a `stripeClientSecret`) constructs the PaymentSheet
    /// and flips `awaitingPayment = true` so CartView presents it. On
    /// failure leaves the cart intact so the user can retry.
    func placeOrder(businessId: Int) async {
        guard !cart.isEmpty, !isPlacing else { return }
        isPlacing = true
        defer { isPlacing = false }

        let items = cart.map {
            OrderItemRequest(menuItemId: $0.menuItemId, quantity: $0.quantity)
        }
        do {
            let response = try await service.placeOrder(
                businessId: businessId,
                items:      items
            )
            currentOrder = response
            cart         = []
            error        = nil

            if let clientSecret = response.stripeClientSecret {
                preparePaymentSheet(clientSecret: clientSecret)
            }
            // No client secret means the server is running without a Stripe
            // key (dev mode) — order is "pay at counter"; no sheet, just go
            // straight to the Order tab.
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

    // MARK: - Payment

    /// Build the Stripe `PaymentSheet` for the freshly-placed order and
    /// arm presentation. `merchantDisplayName` shows in the sheet header;
    /// `allowsDelayedPaymentMethods` is `false` because matcha pickup
    /// expects the payment confirmed before the bar starts the drink.
    func preparePaymentSheet(clientSecret: String) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName          = "Whisked"
        configuration.allowsDelayedPaymentMethods  = false

        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration:             configuration
        )
        paymentResult   = nil
        awaitingPayment = true
    }

    /// Called by CartView's `.paymentSheet(onCompletion:)`. Cancel and
    /// fail both drop the in-flight order so the Order tab doesn't show
    /// a stale unpaid order — the user can re-place from the menu.
    func handlePaymentResult(_ result: PaymentSheetResult) {
        paymentResult   = result
        awaitingPayment = false
        switch result {
        case .completed:
            // Payment succeeded — keep `currentOrder` so the Order tab
            // shows status. CartView's `.onChange(paymentCompleted)`
            // triggers the auto-navigation.
            break
        case .canceled:
            currentOrder = nil
        case .failed(let err):
            self.error  = err.localizedDescription
            currentOrder = nil
        }
    }
}
