// AppDelegate handles the two push notification callbacks that SwiftUI
// doesn't expose via scene lifecycle:
//
//   didRegisterForRemoteNotificationsWithDeviceToken — sends the APNs token
//     to the box fraise backend so it can target this device with loyalty
//     update pushes when a steep is credited.
//
//   didReceiveRemoteNotification — routes silent background pushes.
//     The box-fraise backend sends { notification_type: "order_update" }
//     when an order's status advances; this causes OrderStore to refresh immediately.
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        requestPushPermission(application)
        return true
    }

    // MARK: - Push registration

    private func requestPushPermission(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            Task { @MainActor in application.registerForRemoteNotifications() }
        }
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        // Broadcast the token. AuthStore observes this and registers it with
        // the box fraise backend once the user is authenticated.
        NotificationCenter.default.post(name: .apnsTokenReceived, object: nil, userInfo: ["token": token])
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Non-fatal — foreground refresh still keeps loyalty current.
    }

    // MARK: - Silent push handling

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        handleRemoteNotification(userInfo)
        completionHandler(.newData)
    }
}

