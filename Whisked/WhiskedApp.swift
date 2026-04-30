import SwiftUI
import UserNotifications

@main
struct WhiskedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var authStore     = AuthStore()
    @State private var loyaltyStore  = LoyaltyStore()
    @State private var locationStore = LocationStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authStore)
                .environment(loyaltyStore)
                .environment(locationStore)
                .task { await authStore.bootstrap() }
                .tint(Color.whisked.amber)
                // Refresh loyalty whenever the app returns to the foreground.
                // Covers the case where the user bought something on the box fraise
                // platform and switches back — the balance is always current.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active, authStore.isAuthenticated {
                        Task { await loyaltyStore.refreshBalance() }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .loyaltyDidUpdate)) { _ in
                    Task { await loyaltyStore.refreshBalance() }
                }
                .onOpenURL { url in
                    guard url.scheme == "whisked",
                          url.host == "auth",
                          let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                          let token = items.first(where: { $0.name == "token" })?.value
                    else { return }
                    Task { await authStore.verifyMagicLink(token: token) }
                }
        }
    }
}

// MARK: - Push notification entry point

/// Called by AppDelegate (or the SwiftUI scene delegate) when a remote
/// notification arrives. The box fraise backend sends a silent push with
/// notification_type = "loyalty_update" when a steep is credited to this user.
/// Posting .loyaltyDidUpdate causes any live LoyaltyStore to refresh immediately.
func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
    guard userInfo["notification_type"] as? String == "loyalty_update" else { return }
    NotificationCenter.default.post(name: .loyaltyDidUpdate, object: nil)
}

extension Notification.Name {
    static let loyaltyDidUpdate  = Notification.Name("loyaltyDidUpdate")
    static let apnsTokenReceived = Notification.Name("apnsTokenReceived")
}
