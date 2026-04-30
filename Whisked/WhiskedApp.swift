import SwiftUI

@main
struct WhiskedApp: App {
    @State private var authStore     = AuthStore()
    @State private var loyaltyStore  = LoyaltyStore()
    @State private var locationStore = LocationStore()
    @State private var shopStore     = ShopStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authStore)
                .environment(loyaltyStore)
                .environment(locationStore)
                .environment(shopStore)
                .task { await authStore.bootstrap() }
                .tint(Color.whisked.amber)
        }
    }
}
