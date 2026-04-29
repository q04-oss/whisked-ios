import SwiftUI

/// The persistent bottom sheet that sits over the map.
/// Never dismissible. Three detent positions:
///   - collapsed: search bar only visible
///   - medium:    location list / loyalty summary
///   - large:     full content (detail, loyalty history, profile)
struct SheetContainerView: View {
    @Environment(AuthStore.self)    private var auth
    @Environment(LoyaltyStore.self) private var loyalty
    @Environment(LocationStore.self) private var locations

    @Binding var detent: PresentationDetent

    @State private var query      = ""
    @State private var sheetRoute = SheetRoute.home

    var body: some View {
        VStack(spacing: 0) {
            // ── Search bar ─────────────────────────────────────────────────
            SearchBarView(
                query:         $query,
                onCommand:     handleCommand,
                onSearch:      handleSearch,
                onProfileTap:  { navigate(to: .profile) }
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // ── Content ────────────────────────────────────────────────────
            if detent != .height(88) {
                Divider()
                    .foregroundStyle(Color.whisked.beige)

                Group {
                    switch sheetRoute {
                    case .home:
                        HomeSheetView(onLocationTap: { navigate(to: .location($0)) })
                    case .location(let loc):
                        LocationDetailView(location: loc, onDismiss: { navigate(to: .home) })
                    case .loyalty:
                        LoyaltySheetView(onDismiss: { navigate(to: .home) })
                    case .profile:
                        ProfileSheetView(onDismiss: { navigate(to: .home) })
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: sheetRoute)
            }

            Spacer(minLength: 0)
        }
        .background(Color.whisked.cream)
        // When a location is selected on the map, show its detail.
        .onChange(of: locations.selectedLocation) { _, location in
            if let location {
                navigate(to: .location(location))
                if detent == .height(88) { detent = .medium }
            }
        }
    }

    // MARK: - Navigation

    private func navigate(to route: SheetRoute) {
        withAnimation { sheetRoute = route }
        if detent == .height(88) { detent = .medium }
    }

    // MARK: - Command palette

    private func handleCommand(_ command: String) {
        let lower = command.lowercased()
        if lower.hasPrefix("/business") {
            if lower.hasPrefix("/business/loyalty")   { navigate(to: .loyalty) }
            else                                       { navigate(to: .profile) }
        }
        query = ""
    }

    private func handleSearch(_ text: String) {
        // TODO: route to Claude brand chat
        query = ""
    }
}

// MARK: - Route

enum SheetRoute: Equatable {
    case home
    case location(WhiskedLocation)
    case loyalty
    case profile
}
