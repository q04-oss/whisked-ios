// OrderStatusView surfaces the customer's current order through three
// lifecycle stages. The pickup code is the headline once the order goes
// `.ready` — staff scan or visually verify it at handover.
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
        }
    }
}

// MARK: - Detail

private struct OrderDetail: View {
    let order: Order

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 24)
            statusBadge

            if order.status == .ready, let code = order.pickupCode {
                Text(code)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.whisked.amber)
                    .padding(.top, 8)
                Text("Show this at pickup")
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
        Text(order.status.rawValue.uppercased())
            .font(.caption.weight(.bold))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(badgeColor.opacity(0.18), in: Capsule())
            .foregroundStyle(badgeColor)
    }

    private var badgeColor: Color {
        switch order.status {
        case .pending:    return Color.whisked.stone
        case .preparing:  return Color.whisked.amber
        case .ready:      return .green
        case .collected:  return Color.whisked.stone
        }
    }

    private var statusMessage: String {
        switch order.status {
        case .pending:    return "Order received. We're queuing it up."
        case .preparing:  return "Your drink is being prepared."
        case .ready:      return "Ready for pickup."
        case .collected:  return "Enjoy."
        }
    }
}
