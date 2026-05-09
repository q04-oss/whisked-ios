import Foundation

/// One menu item served by the bar. The catalogue is fetched from
/// `GET /api/whisked/menu` (stubbed locally until the endpoint lands).
struct MenuItem: Codable, Identifiable, Hashable {
    let id:          Int
    let name:        String
    let description: String?
    let priceCents:  Int

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case priceCents = "price_cents"
    }

    /// Decimal CAD for display. Avoids floating-point drift when summing
    /// line totals.
    var price: Decimal { Decimal(priceCents) / 100 }
}

/// One row in the local cart. `id` is a fresh UUID per add so quantity
/// changes and removes target the right row even if the user adds the
/// same `MenuItem` twice.
struct CartItem: Codable, Identifiable, Hashable {
    let id:       UUID
    let menuItem: MenuItem
    var quantity: Int

    var lineTotal: Decimal { menuItem.price * Decimal(quantity) }
}

/// Server-side order lifecycle. `pickup_code` only populates once the
/// order reaches `.ready`.
enum OrderStatus: String, Codable {
    case pending
    case preparing
    case ready
    case collected
}

/// A placed order. Returned by `POST /api/whisked/orders` and refreshed by
/// `GET /api/whisked/orders/:id`.
struct Order: Codable, Identifiable {
    let id:         Int
    let status:     OrderStatus
    let pickupCode: String?
    let totalCents: Int
    let createdAt:  Date
    let items:      [OrderLine]

    enum CodingKeys: String, CodingKey {
        case id, status, items
        case pickupCode = "pickup_code"
        case totalCents = "total_cents"
        case createdAt  = "created_at"
    }
}

struct OrderLine: Codable, Identifiable, Hashable {
    let id:           Int
    let menuItemId:   Int
    let menuItemName: String
    let quantity:     Int
    let priceCents:   Int

    enum CodingKeys: String, CodingKey {
        case id, quantity
        case menuItemId   = "menu_item_id"
        case menuItemName = "menu_item_name"
        case priceCents   = "price_cents"
    }
}
