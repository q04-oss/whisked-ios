// Wire models for the Whisked menu / order endpoints on box-fraise-platform.
//
// The server-side row names (`WhiskedMenuItemRow`, `WhiskedOrderRow`, …) are
// preserved here so a developer cross-referencing the Rust types in
// `domain/src/domain/whisked_orders/types.rs` sees the same names on both
// sides. JSON keys come over as snake_case; each struct declares explicit
// `CodingKeys` to match the project pattern (see `AuthModels.swift`).
import Foundation

// MARK: - Menu

struct WhiskedMenuItemRow: Codable, Identifiable, Hashable {
    let id:          Int
    let name:        String
    let description: String?
    let priceCents:  Int
    let category:    String
    let available:   Bool
    let sortOrder:   Int
    let createdAt:   Date
    let updatedAt:   Date

    enum CodingKeys: String, CodingKey {
        case id, name, description, category, available
        case priceCents = "price_cents"
        case sortOrder  = "sort_order"
        case createdAt  = "created_at"
        case updatedAt  = "updated_at"
    }

    /// Decimal CAD for display — `Int(priceCents) / 100` would lose the
    /// fractional unit when formatters expect a Decimal/Double.
    var price: Decimal { Decimal(priceCents) / 100 }
}

// MARK: - Order rows

struct WhiskedOrderItemRow: Codable, Identifiable, Hashable {
    let id:          Int
    let orderId:     Int
    let menuItemId:  Int
    let quantity:    Int
    let priceCents:  Int

    enum CodingKeys: String, CodingKey {
        case id, quantity
        case orderId    = "order_id"
        case menuItemId = "menu_item_id"
        case priceCents = "price_cents"
    }

    var lineTotal: Decimal { Decimal(priceCents) * Decimal(quantity) / 100 }
}

struct WhiskedOrderRow: Codable, Identifiable, Hashable {
    let id:                    Int
    let userId:                Int
    let businessId:            Int
    let status:                String
    let totalCents:            Int
    let stripePaymentIntentId: String?
    let pickupCode:            String
    let pickupCodeUsedAt:      Date?
    let estimatedPickupAt:     Date?
    let createdAt:             Date
    let updatedAt:             Date

    enum CodingKeys: String, CodingKey {
        case id, status
        case userId                = "user_id"
        case businessId            = "business_id"
        case totalCents            = "total_cents"
        case stripePaymentIntentId = "stripe_payment_intent_id"
        case pickupCode            = "pickup_code"
        case pickupCodeUsedAt      = "pickup_code_used_at"
        case estimatedPickupAt     = "estimated_pickup_at"
        case createdAt             = "created_at"
        case updatedAt             = "updated_at"
    }
}

/// Top-level wire response from POST /api/whisked/orders and GET
/// /api/whisked/orders/:id. `stripeClientSecret` is one-shot at placement;
/// subsequent fetches return `nil` (the iOS Stripe SDK caches the secret
/// locally for the in-flight order).
struct WhiskedOrderResponse: Codable, Hashable {
    let order:              WhiskedOrderRow
    let items:              [WhiskedOrderItemRow]
    let pickupCode:         String
    let stripeClientSecret: String?
    let customerName:       String?

    enum CodingKeys: String, CodingKey {
        case order, items
        case pickupCode         = "pickup_code"
        case stripeClientSecret = "stripe_client_secret"
        case customerName       = "customer_name"
    }
}

// MARK: - Request bodies

struct PlaceOrderRequest: Codable {
    let businessId: Int
    let items:      [OrderItemRequest]

    enum CodingKeys: String, CodingKey {
        case businessId = "business_id"
        case items
    }
}

struct OrderItemRequest: Codable, Hashable {
    let menuItemId: Int
    let quantity:   Int

    enum CodingKeys: String, CodingKey {
        case menuItemId = "menu_item_id"
        case quantity
    }
}

// MARK: - Local cart

/// Local cart line. Created fresh from a `WhiskedMenuItemRow` on add; never
/// crosses the wire. `id` is a fresh UUID per add so quantity changes and
/// removes target the right row even if the same menu item gets added twice.
struct CartItem: Identifiable, Hashable {
    let id         = UUID()
    let menuItemId: Int
    let name:       String
    let priceCents: Int
    var quantity:   Int

    var lineTotal: Decimal { Decimal(priceCents) * Decimal(quantity) / 100 }
}
