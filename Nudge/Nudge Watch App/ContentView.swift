import SwiftUI
import UserNotifications
import WatchKit

struct ContentView: View {
    /// How often to tap. Change this to adjust the cadence.
    private let interval: TimeInterval = 20 * 60

    private let requestID = "com.ivankaliaev.nudge.tap"

    // Wall-clock anchor of the last Start press, so the countdown survives
    // the app being suspended and relaunched.
    @AppStorage("startedAt") private var startedAt: Double = 0
    @State private var isRunning = false
    @State private var authDenied = false

    var body: some View {
        VStack(spacing: 12) {
            if isRunning {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(countdown(at: context.date))
                        .font(.system(.title, design: .rounded).monospacedDigit())
                }
                Text("until the next tap")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("A single tap every \(Int(interval / 60)) minutes")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(isRunning ? "Stop" : "Start") {
                if isRunning {
                    stop()
                } else {
                    start()
                }
            }
            .tint(isRunning ? .red : .green)

            if authDenied {
                Text("Notifications are off — taps only work while Nudge is open. Enable them in Settings → Notifications → Nudge.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .task { await refreshState() }
    }

    private func start() {
        Task {
            let center = UNUserNotificationCenter.current()
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            authDenied = !granted

            let content = UNMutableNotificationContent()
            content.title = "Nudge"
            content.body = "\(Int(interval / 60)) minutes are up."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: true)
            try? await center.add(UNNotificationRequest(identifier: requestID, content: content, trigger: trigger))

            startedAt = Date.now.timeIntervalSince1970
            isRunning = true
            // A sample of the tap, so you know what to listen (feel) for.
            WKInterfaceDevice.current().play(.click)
        }
    }

    private func stop() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestID])
        isRunning = false
        startedAt = 0
    }

    private func refreshState() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        isRunning = pending.contains { $0.identifier == requestID }
        authDenied = await center.notificationSettings().authorizationStatus == .denied
    }

    private func countdown(at date: Date) -> String {
        let elapsed = max(0, date.timeIntervalSince1970 - startedAt)
        let remaining = interval - elapsed.truncatingRemainder(dividingBy: interval)
        let seconds = max(0, Int(remaining.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    ContentView()
}
