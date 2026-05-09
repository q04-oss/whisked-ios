// RootView is the single auth gate. The `.checking` state shows a spinner
// while AuthStore.bootstrap restores tokens; on `.unauthenticated` /
// `.awaitingMagicLink` we show the magic-link AuthView; on `.authenticated`
// we show the four-tab MainTabView.
import SwiftUI

struct RootView: View {
    @Environment(AuthStore.self) private var auth

    var body: some View {
        switch auth.state {
        case .checking:
            VStack {
                ProgressView()
                    .controlSize(.large)
                    .tint(Color.whisked.amber)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.whisked.cream.ignoresSafeArea())

        case .unauthenticated, .awaitingMagicLink:
            AuthView()

        case .authenticated:
            MainTabView()
        }
    }
}
