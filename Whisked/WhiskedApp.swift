// Whisked iOS — customer-facing client for the box-fraise-platform backend.
// `WHISKED_API_BASE_URL` (Secrets.xcconfig) must point at the box-fraise
// deployment; the app does not talk to a separate Whisked-only backend.
//
// Requires the StripePaymentSheet SPM dependency — added via Xcode (see
// Package.swift and the README "Stripe setup" section).
import SwiftUI
import UserNotifications
import StripePaymentSheet

@main
struct WhiskedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var authStore  = AuthStore()
    @State private var orderStore = OrderStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Configure the Stripe SDK with the publishable key once, at App
        // construction. Stripe stores this globally on `StripeAPI`, so
        // subsequent PaymentSheet inits pick it up automatically.
        StripeAPI.defaultPublishableKey = Config.stripePublishableKey
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authStore)
                .environment(orderStore)
                .task { await authStore.bootstrap() }
                // Refresh the in-flight order whenever the app comes back to
                // the foreground so a "ready" status surfaces without forcing
                // the user to pull-to-refresh.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active, authStore.isAuthenticated {
                        Task { await orderStore.refreshOrderStatus() }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .orderDidUpdate)) { _ in
                    Task { await orderStore.refreshOrderStatus() }
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
/// notification arrives. The box-fraise backend sends a silent push with
/// notification_type = "order_update" when an order's status advances
/// (pending → preparing → ready). Posting `.orderDidUpdate` causes any live
/// `OrderStore` to refresh immediately.
func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
    guard userInfo["notification_type"] as? String == "order_update" else { return }
    NotificationCenter.default.post(name: .orderDidUpdate, object: nil)
}

extension Notification.Name {
    static let orderDidUpdate    = Notification.Name("orderDidUpdate")
    static let apnsTokenReceived = Notification.Name("apnsTokenReceived")
}
