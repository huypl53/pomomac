import Foundation
import UserNotifications
import AppKit

final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notifyPhaseEnded(ended: Phase, next: Phase, playSound: Bool) {
        let content = UNMutableNotificationContent()

        switch ended {
        case .work:
            content.title = "Work session done!"
            content.body = next == .longBreak
                ? "Great job — take a long break."
                : "Nice — take a short break."
        case .shortBreak, .longBreak:
            content.title = "Break over!"
            content.body = "Back to focus — start your next pomodoro."
        }

        if playSound {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // Show banner even when app is "active"
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
