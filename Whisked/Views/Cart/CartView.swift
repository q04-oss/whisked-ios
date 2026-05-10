// CartView shows the items the customer has added, the running total, and
// the "Place order" CTA. The post-tap flow:
//   1. tap "Place order" → OrderStore.placeOrder() → POST /api/whisked/orders
//   2. server returns `stripeClientSecret` → OrderStore.preparePaymentSheet
//      sets `awaitingPayment = true`
//   3. `.paymentSheet(isPresented: …)` modifier here picks that up and
//      shows the Stripe-native PaymentSheet
//   4. on `.completed` → auto-present OrderStatusView so the customer
//      sees "your drink is being prepared / ready / W-XXXX"
//   5. on `.canceled` / `.failed` → OrderStore drops the order; user lands
//      back on a clean cart
//
// Requires the StripePaymentSheet SPM dependency — added via Xcode.
import SwiftUI
import StripePaymentSheet

struct CartView: View {
    @Environment(OrderStore.self) private var store
    @State private var showOrderStatus = false

    var body: some View {
        // Re-bind the env-injected store as a Bindable so `$store.…`
        // produces the `Binding<Bool>` that `.paymentSheet` and `.sheet`
        // need. This is the SwiftUI 17 / Observation pattern.
        @Bindable var store = store

        NavigationStack {
            Group {
                if store.cart.isEmpty {
                    ContentUnavailableView(
                        "Your cart is empty",
                        systemImage: "bag",
                        description: Text("Add a drink from the Menu tab.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(store.cart) { item in
                                CartRow(item: item)
                            }
                            .onDelete { indexSet in
                                for idx in indexSet {
                                    store.removeFromCart(store.cart[idx])
                                }
                            }
                        }

                        Section {
                            HStack {
                                Text("Total").font(.headline)
                                Spacer()
                                Text(
                                    Decimal(store.cartTotalCents) / 100,
                                    format: .currency(code: "CAD")
                                )
                                    .font(.headline)
                            }

                            if let error = store.error {
                                Text(error)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }

                            PrimaryButton(title: "Place order", isLoading: store.isPlacing) {
                                await store.placeOrder(businessId: Config.businessID)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                }
            }
            .navigationTitle("Cart")
            // Stripe PaymentSheet — armed when OrderStore.preparePaymentSheet
            // ran. The fallback sheet only ever exists at compile time;
            // `awaitingPayment` is only ever set true alongside `paymentSheet`.
            .paymentSheet(
                isPresented:  $store.awaitingPayment,
                paymentSheet: store.paymentSheet ?? placeholderSheet,
                onCompletion: { result in store.handlePaymentResult(result) }
            )
            // Auto-open the OrderStatusView when payment completes so the
            // customer immediately sees prep status / pickup code instead
            // of staring at an empty cart.
            .onChange(of: store.paymentCompleted) { _, completed in
                if completed { showOrderStatus = true }
            }
            .sheet(isPresented: $showOrderStatus) {
                NavigationStack {
                    OrderStatusView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showOrderStatus = false }
                            }
                        }
                }
            }
        }
    }

    /// Fallback PaymentSheet used only to satisfy the type at compile time
    /// — `awaitingPayment` is `false` whenever `paymentSheet` is `nil`, so
    /// this object is never actually presented. A throwaway empty secret
    /// keeps initialization cheap.
    private var placeholderSheet: PaymentSheet {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Whisked"
        return PaymentSheet(paymentIntentClientSecret: "", configuration: configuration)
    }
}

// MARK: - Row

private struct CartRow: View {
    let item: CartItem

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .foregroundStyle(Color.whisked.ink)
                Text("Qty \(item.quantity)")
                    .font(.caption)
                    .foregroundStyle(Color.whisked.stone)
            }
            Spacer()
            Text(item.lineTotal, format: .currency(code: "CAD"))
                .foregroundStyle(Color.whisked.stone)
        }
    }
}
