// ShopModels defines the types used by the Shopify storefront integration.
// These are distinct from the backend domain types — they represent Shopify's
// data model, not the Whisked operational model.
import Foundation

struct ShopProduct: Identifiable, Equatable {
    let id:          String
    let title:       String
    let description: String
    let minPrice:    String   // decimal string from Shopify
    let currency:    String
    let imageURL:    URL?
    let variants:    [ShopVariant]

    var formattedPrice: String {
        guard let amount = Decimal(string: minPrice) else { return minPrice }
        return amount.formatted(.currency(code: currency))
    }
}

struct ShopVariant: Identifiable, Equatable {
    let id:               String
    let title:            String
    let price:            String
    let currency:         String
    let availableForSale: Bool

    var formattedPrice: String {
        guard let amount = Decimal(string: price) else { return price }
        return amount.formatted(.currency(code: currency))
    }
}
