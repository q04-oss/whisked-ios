import SwiftUI

struct MainTabView: View {
    @Environment(LoyaltyStore.self) private var loyalty

    var body: some View {
        TabView {
            BalanceView()
                .tabItem {
                    Label("Steeps", systemImage: "leaf.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .task { await loyalty.load() }
    }
}
