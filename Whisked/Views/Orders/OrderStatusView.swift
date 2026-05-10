// OrderStatusView surfaces the customer's current order through three
// lifecycle stages. The pickup code is the headline once the order goes
// `.ready` — staff scan or visually verify it at handover.
//
// While the view is on-screen it polls `refreshOrderStatus` every 5
// seconds so a `.ready` status appears without the customer pulling-to-
// refresh. The polling task is owned by `.task`, which auto-cancels on
// disappear; no leaked timers.
import SwiftUI

struct OrderStatusView: View {
    @Environment(OrderStore.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if let order = store.currentOrder {
                    OrderDetail(order: order)
                } else {
                    ContentUnavailableView(
                        "No active order",
                        systemImage: "clock",
                        description: Text("Place an order from the Menu tab.")
                    )
                }
            }
            .navigationTitle("Order")
            .task {
                // Poll every 5s while visible. Task is cancelled when the view
                // disappears (tab switch, sign-out, etc.) — no leaked timer.
                while !Task.isCancelled {
                    await store.refreshOrderStatus()
                    try? await Task.sleep(for: .seconds(5))
                }
            }
        }
    }
}

// MARK: - Detail

private struct OrderDetail: View {
    let order: WhiskedOrderResponse

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 24)
            statusBadge

            if order.order.status == "ready" {
                Text(order.pickupCode)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.whisked.amber)
                    .padding(.top, 8)
                Text("Show this code to staff")
                    .font(.subheadline)
                    .foregroundStyle(Color.whisked.stone)
            } else {
                Text(statusMessage)
                    .font(.title3)
                    .foregroundStyle(Color.whisked.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var statusBadge: some View {
        Text(order.order.status.uppercased())
            .font(.caption.weight(.bold))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(badgeColor.opacity(0.18), in: Capsule())
            .foregroundStyle(badgeColor)
    }

    private var badgeColor: Color {
        switch order.order.status {
        case "preparing":  return Color.whisked.amber
        case "ready":      return .green
        case "collected":  return Color.whisked.stone
        default:           return Color.whisked.stone
        }
    }

    private var statusMessage: String {
        switch order.order.status {
        case "pending":    return "Your order has been received."
        case "preparing":  return "Your order is being prepared."
        case "ready":      return "Ready for pickup."
        case "collected":  return "Enjoy."
        case "cancelled":  return "Order cancelled."
        default:           return order.order.status.capitalized
        }
    }
}
