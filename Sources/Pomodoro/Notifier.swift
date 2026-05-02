import Foundation
import UserNotifications
import AppKit

final class Notifier: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        refreshStatus()
    }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { [weak self] in
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error {
                        NSLog("Pomodoro: auth request failed: \(error.localizedDescription)")
                    } else {
                        NSLog("Pomodoro: notifications granted=\(granted)")
                    }
                    DispatchQueue.main.async { [weak self] in self?.refreshStatus() }
                }
            case .denied:
                NSLog("Pomodoro: notifications denied — enable in System Settings → Notifications → Pomodoro")
            default:
                break
            }
        }
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
        post(content: content, playSound: playSound)
    }

    /// Fire a synthetic notification for diagnostics.
    func sendTestNotification(playSound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro test"
        content.body = "If you see this, notifications are working."
        post(content: content, playSound: playSound)
    }

    private func post(content: UNMutableNotificationContent, playSound: Bool) {
        if playSound { content.sound = .default }
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                NSLog("Pomodoro: notification post failed: \(error.localizedDescription)")
            }
        }
    }

    // Show banner + sound even when app is "active" (status-bar apps usually are).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
