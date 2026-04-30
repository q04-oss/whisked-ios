// ShopStore fetches and caches the Whisked Shopify product catalog.
// Products are loaded once on first access and refreshed on pull-to-refresh.
import Foundation
import Observation

@Observable
@MainActor
final class ShopStore {
    private(set) var products:  [ShopProduct] = []
    private(set) var isLoading  = false
    private(set) var error:     ShopifyError?

    private let client = ShopifyClient.shared

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        error     = nil
        do {
            products = try await client.fetchProducts()
        } catch let e as ShopifyError {
            self.error = e
        } catch {
            self.error = .requestFailed
        }
        isLoading = false
    }

    /// Returns the Shopify checkout URL for a variant.
    /// Open in SFSafariViewController — Shopify handles payment.
    func checkoutURL(for variant: ShopVariant) -> URL? {
        client.checkoutURL(variantID: variant.id)
    }
}
