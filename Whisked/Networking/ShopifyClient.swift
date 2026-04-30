// ShopifyClient fetches product data from the Whisked Shopify storefront.
//
// The Storefront API uses a public access token — Shopify designed it for
// client-side use. It is read-only and scoped only to storefront data.
// Payment is handled by Shopify's hosted checkout opened in SFSafariViewController.
// The app never handles card data.
//
// Configure WHISKED_SHOPIFY_STORE_DOMAIN and WHISKED_SHOPIFY_STOREFRONT_TOKEN
// in Secrets.xcconfig.
import Foundation

struct ShopifyClient {

    private let storeDomain: String
    private let storefrontToken: String

    static let shared = ShopifyClient(
        storeDomain:      Bundle.main.infoDictionary?["WHISKED_SHOPIFY_STORE_DOMAIN"] as? String ?? "",
        storefrontToken:  Bundle.main.infoDictionary?["WHISKED_SHOPIFY_STOREFRONT_TOKEN"] as? String ?? ""
    )

    // MARK: - Products

    func fetchProducts() async throws -> [ShopProduct] {
        let query = """
        {
          products(first: 20) {
            edges {
              node {
                id
                title
                description
                priceRange { minVariantPrice { amount currencyCode } }
                images(first: 1) { edges { node { url altText } } }
                variants(first: 5) {
                  edges {
                    node { id title price { amount currencyCode } availableForSale }
                  }
                }
              }
            }
          }
        }
        """

        let data = try await graphql(query: query)
        return try parseProducts(from: data)
    }

    // MARK: - Checkout

    /// Returns a Shopify web checkout URL for the given variant.
    /// Open this in SFSafariViewController — Shopify handles payment and PCI.
    func checkoutURL(variantID: String, quantity: Int = 1) -> URL? {
        guard !storeDomain.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "https"
        components.host   = storeDomain
        components.path   = "/cart/\(variantID.shopifyNumericID):\(quantity)"
        return components.url
    }

    // MARK: - GraphQL

    private func graphql(query: String) async throws -> Data {
        guard !storeDomain.isEmpty, !storefrontToken.isEmpty else {
            throw ShopifyError.notConfigured
        }

        guard let url = URL(string: "https://\(storeDomain)/api/2024-01/graphql.json") else {
            throw ShopifyError.invalidConfiguration
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(storefrontToken, forHTTPHeaderField: "X-Shopify-Storefront-Access-Token")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["query": query])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw ShopifyError.requestFailed
        }
        return data
    }

    // MARK: - Parsing

    private func parseProducts(from data: Data) throws -> [ShopProduct] {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let edges = (json?["data"] as? [String: Any])?["products"] as? [String: Any],
              let productEdges = edges["edges"] as? [[String: Any]]
        else { return [] }

        return productEdges.compactMap { edge -> ShopProduct? in
            guard let node = edge["node"] as? [String: Any],
                  let id    = node["id"] as? String,
                  let title = node["title"] as? String
            else { return nil }

            let description = node["description"] as? String ?? ""

            let priceRange  = node["priceRange"] as? [String: Any]
            let minPrice    = (priceRange?["minVariantPrice"] as? [String: Any])?["amount"] as? String ?? "0"
            let currency    = (priceRange?["minVariantPrice"] as? [String: Any])?["currencyCode"] as? String ?? "CAD"

            let imageURL: URL? = {
                let edges = (node["images"] as? [String: Any])?["edges"] as? [[String: Any]]
                let urlStr = ((edges?.first?["node"] as? [String: Any])?["url"] as? String) ?? ""
                return URL(string: urlStr)
            }()

            let variants: [ShopVariant] = {
                let vedges = (node["variants"] as? [String: Any])?["edges"] as? [[String: Any]] ?? []
                return vedges.compactMap { vedge -> ShopVariant? in
                    guard let vnode  = vedge["node"] as? [String: Any],
                          let vid    = vnode["id"] as? String,
                          let vtitle = vnode["title"] as? String,
                          let avail  = vnode["availableForSale"] as? Bool
                    else { return nil }
                    let vprice = (vnode["price"] as? [String: Any])?["amount"] as? String ?? "0"
                    return ShopVariant(id: vid, title: vtitle, price: vprice, currency: currency, availableForSale: avail)
                }
            }()

            return ShopProduct(
                id:          id,
                title:       title,
                description: description,
                minPrice:    minPrice,
                currency:    currency,
                imageURL:    imageURL,
                variants:    variants
            )
        }
    }
}

enum ShopifyError: LocalizedError {
    case notConfigured
    case invalidConfiguration
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:       return "Shopify is not configured."
        case .invalidConfiguration: return "Invalid Shopify configuration."
        case .requestFailed:       return "Could not reach the Whisked store."
        }
    }
}

private extension String {
    /// Extracts the numeric ID from a Shopify global ID like "gid://shopify/ProductVariant/12345".
    var shopifyNumericID: String {
        components(separatedBy: "/").last ?? self
    }
}
