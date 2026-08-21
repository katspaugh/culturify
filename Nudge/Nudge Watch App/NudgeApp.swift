import SwiftUI
import UserNotifications
import WatchKit

@main
struct NudgeApp: App {
    @WKApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = self
    }

    // When the app is on screen there's no need for a banner — the system
    // won't play the notification haptic for a foreground app, so play the
    // tap ourselves and swallow the presentation.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        WKInterfaceDevice.current().play(.click)
        return []
    }
}
