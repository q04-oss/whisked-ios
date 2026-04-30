// ShopView is the Whisked retail catalog — ceremonial matcha tins and merchandise.
// Products are fetched from the Shopify Storefront API. Tapping a product opens
// ProductDetailView where the customer can select a variant and proceed to checkout.
// Checkout opens in SFSafariViewController — Shopify handles payment and PCI compliance.
import SafariServices
import SwiftUI

struct ShopView: View {
    @Environment(ShopStore.self) private var shop
    let onDismiss: () -> Void

    @State private var selectedProduct: ShopProduct?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── Header ─────────────────────────────────────────────────
                HStack {
                    Text("Shop")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.whisked.ink)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.whisked.stone)
                            .padding(8)
                            .background(Color.whisked.stone.opacity(0.08), in: Circle())
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 24)

                if shop.isLoading {
                    ProgressView()
                        .tint(Color.whisked.stone)
                        .padding(.top, 48)

                } else if let error = shop.error {
                    VStack(spacing: 12) {
                        Text(error.localizedDescription)
                            .font(.footnote)
                            .foregroundStyle(Color.whisked.stone)
                        Button("Try again") { Task { await shop.load() } }
                            .font(.footnote)
                            .foregroundStyle(Color.whisked.amber)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 48)

                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(shop.products) { product in
                            ProductRow(product: product)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedProduct = product }

                            if product.id != shop.products.last?.id {
                                Divider().padding(.leading, 32)
                            }
                        }
                    }
                }

                Spacer(minLength: 32)
            }
        }
        .scrollIndicators(.hidden)
        .task { if shop.products.isEmpty { await shop.load() } }
        .sheet(item: $selectedProduct) { product in
            ProductDetailView(product: product)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Product row

private struct ProductRow: View {
    let product: ShopProduct

    var body: some View {
        HStack(spacing: 16) {
            // Product image
            AsyncImage(url: product.imageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.whisked.beige
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(product.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.whisked.ink)
                Text(product.formattedPrice)
                    .font(.footnote)
                    .foregroundStyle(Color.whisked.stone)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 14)
    }
}
