// CartView shows the items the customer has added, the running total, and
// the "Place order" CTA. Placing an order clears the cart and creates an
// in-flight order on the OrderStore — the Order tab takes over from there.
import SwiftUI

struct CartView: View {
    @Environment(OrderStore.self) private var store

    var body: some View {
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
                                Text(store.cartTotal, format: .currency(code: "CAD"))
                                    .font(.headline)
                            }

                            PrimaryButton(title: "Place order", isLoading: store.isPlacing) {
                                await store.placeOrder()
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                }
            }
            .navigationTitle("Cart")
        }
    }
}

// MARK: - Row

private struct CartRow: View {
    let item: CartItem

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.menuItem.name)
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
