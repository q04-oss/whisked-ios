import SwiftUI

@main
struct WhiskedApp: App {
    @State private var authStore     = AuthStore()
    @State private var loyaltyStore  = LoyaltyStore()
    @State private var locationStore = LocationStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authStore)
                .environment(loyaltyStore)
                .environment(locationStore)
                .task { await authStore.bootstrap() }
                .tint(Color.whisked.amber)
        }
    }
}
