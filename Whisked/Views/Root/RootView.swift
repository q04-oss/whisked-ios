import SwiftUI

/// Auth gate. Switches between the login flow and the main app based on
/// AuthStore state. The `.checking` state shows a neutral launch screen
/// while tokens are validated — never a flash of the wrong screen.
struct RootView: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        switch auth.state {
        case .checking:
            // Matches the launch screen background — invisible transition.
            Color(.systemBackground)
                .ignoresSafeArea()

        case .unauthenticated:
            AuthNavigationView()
                .transition(.opacity)

        case .authenticated:
            MainTabView()
                .transition(.opacity)
        }
    }
}
