import SwiftUI

@main
struct WhiskedApp: App {
    @State private var authStore    = AuthStore()
    @State private var loyaltyStore = LoyaltyStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authStore)
                .environment(loyaltyStore)
                .task { await authStore.bootstrap() }
        }
    }
}
