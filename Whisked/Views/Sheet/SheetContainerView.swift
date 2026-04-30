// SheetContainerView is the layout root of the persistent sheet.
//
// It is responsible for two things only: rendering the search bar header and
// switching the content area based on the current SheetRoute. All navigation
// logic and detent management live in SheetRouter. All business logic lives in
// the domain stores. This view is deliberately thin.
import SwiftUI

struct SheetContainerView: View {
    @Environment(SheetRouter.self)   private var router
    @Environment(LocationStore.self) private var locations

    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            // ── Search bar ─────────────────────────────────────────────────
            SearchBarView(
                query:        $query,
                onCommand:    { router.handle(command: $0); query = "" },
                onSearch:     { _ in query = "" },   // TODO: Claude brand chat
                onProfileTap: { router.navigate(to: .profile) }
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // ── Content ────────────────────────────────────────────────────
            if router.detent != .height(88) {
                Divider().foregroundStyle(Color.whisked.beige)
                sheetContent
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: router.route)
            }

            Spacer(minLength: 0)
        }
        .background(Color.whisked.cream)
        // Sync map pin selection → sheet navigation.
        .onChange(of: locations.selectedLocation) { _, location in
            if let location { router.navigate(to: .location(location)) }
        }
    }

    // MARK: - Content routing

    @ViewBuilder
    private var sheetContent: some View {
        switch router.route {
        case .home:
            HomeSheetView(
                onLocationTap: { router.navigate(to: .location($0)) },
                onShopTap:     { router.navigate(to: .shop) }
            )
        case .location(let location):
            LocationDetailView(location: location) { router.navigate(to: .home) }
        case .loyalty:
            LoyaltySheetView(
                onDismiss: { router.navigate(to: .home) },
                onShowQR:  { router.navigate(to: .qrCode) }
            )
        case .qrCode:
            LoyaltyQRView { router.navigate(to: .loyalty) }
        case .shop:
            ShopView { router.navigate(to: .home) }
        case .profile:
            ProfileSheetView { router.navigate(to: .home) }
        }
    }
}
