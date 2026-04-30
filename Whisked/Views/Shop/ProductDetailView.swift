// ProductDetailView shows a single Shopify product with variant selection.
// The checkout button opens Shopify's hosted checkout in SFSafariViewController.
// The app never handles payment — Shopify is responsible for PCI compliance.
import SafariServices
import SwiftUI

struct ProductDetailView: View {
    @Environment(ShopStore.self) private var shop
    let product: ShopProduct

    @State private var selectedVariant: ShopVariant?
    @State private var showSafari      = false
    @State private var checkoutURL:    URL?

    private var variant: ShopVariant {
        selectedVariant ?? product.variants.first ?? ShopVariant(id: "", title: "", price: "0", currency: "CAD", availableForSale: false)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── Image ──────────────────────────────────────────────────
                AsyncImage(url: product.imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.whisked.beige
                }
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .clipped()

                VStack(alignment: .leading, spacing: 0) {

                    // ── Title + price ──────────────────────────────────────
                    HStack(alignment: .top) {
                        Text(product.title)
                            .font(.title3.bold())
                            .foregroundStyle(Color.whisked.ink)
                        Spacer()
                        Text(variant.formattedPrice)
                            .font(.subheadline)
                            .foregroundStyle(Color.whisked.stone)
                    }
                    .padding(.top, 24)

                    // ── Description ────────────────────────────────────────
                    if !product.description.isEmpty {
                        Text(product.description)
                            .font(.footnote)
                            .foregroundStyle(Color.whisked.stone)
                            .padding(.top, 10)
                            .lineSpacing(4)
                    }

                    // ── Variant picker ─────────────────────────────────────
                    if product.variants.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Option")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.whisked.stone)
                                .tracking(1)
                                .textCase(.uppercase)
                                .padding(.top, 24)

                            HStack(spacing: 8) {
                                ForEach(product.variants) { v in
                                    Button(v.title) {
                                        selectedVariant = v
                                    }
                                    .font(.footnote)
                                    .foregroundStyle(variant.id == v.id ? Color.whisked.ink : Color.whisked.stone)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        variant.id == v.id
                                            ? Color.whisked.yellow.opacity(0.4)
                                            : Color.whisked.beige,
                                        in: Capsule()
                                    )
                                    .disabled(!v.availableForSale)
                                    .opacity(v.availableForSale ? 1 : 0.4)
                                }
                            }
                        }
                    }

                    // ── Buy button ─────────────────────────────────────────
                    PrimaryButton(title: variant.availableForSale ? "Buy on Whisked" : "Sold out") {
                        guard let url = shop.checkoutURL(for: variant) else { return }
                        checkoutURL = url
                        showSafari  = true
                    }
                    .padding(.top, 32)
                    .disabled(!variant.availableForSale)
                    .opacity(variant.availableForSale ? 1 : 0.5)

                    Text("Secured by Shopify")
                        .font(.caption2)
                        .foregroundStyle(Color.whisked.stone.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showSafari) {
            if let url = checkoutURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Safari wrapper

private struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
