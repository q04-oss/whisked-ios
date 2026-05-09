// MainTabView is the four-tab post-auth shell: Menu, Cart, Order, Profile.
// Created here rather than in RootView so RootView can remain a pure auth
// gate that doesn't know about the tabbed structure.
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            MenuView()
                .tabItem { Label("Menu", systemImage: "list.bullet") }

            CartView()
                .tabItem { Label("Cart", systemImage: "bag") }

            OrderStatusView()
                .tabItem { Label("Order", systemImage: "clock") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
        .tint(Color.whisked.amber)
    }
}
