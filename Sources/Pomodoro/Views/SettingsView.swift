import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var launchAtLogin: LaunchAtLogin
    @EnvironmentObject var notifier: Notifier

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            stepperRow("Work", value: $settings.workMinutes, range: 1...60, suffix: "min")
            stepperRow("Short break", value: $settings.shortBreakMinutes, range: 1...30, suffix: "min")
            stepperRow("Long break", value: $settings.longBreakMinutes, range: 1...60, suffix: "min")
            stepperRow("Sessions until long", value: $settings.sessionsUntilLongBreak, range: 2...8, suffix: "")

            Toggle("Auto-start next phase", isOn: $settings.autoStartNextPhase)
                .font(.system(size: 12))
            Toggle("Play sound on alert", isOn: $settings.playSound)
                .font(.system(size: 12))
            Toggle("Launch at login", isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setEnabled($0) }
            ))
            .font(.system(size: 12))

            if launchAtLogin.requiresApproval {
                Text("Approve in System Settings → General → Login Items.")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                if notifier.authorizationStatus == .denied {
                    HStack(spacing: 6) {
                        Text("Notifications disabled.")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Button("Open Settings") {
                            openNotificationSettings()
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.borderless)
                    }
                } else if notifier.authorizationStatus == .notDetermined {
                    Button("Enable notifications") {
                        notifier.requestAuthorization()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.borderless)
                }
                HStack {
                    Spacer()
                    Button("Test alert") {
                        notifier.sendTestNotification(playSound: settings.playSound)
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.borderless)
                }
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .onAppear {
            launchAtLogin.refresh()
            notifier.refreshStatus()
        }
    }

    @ViewBuilder
    private func stepperRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>, suffix: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12))
            Spacer()
            TextField("", value: clamped(value, in: range), format: .number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 44)
                .font(.system(size: 12))
            if !suffix.isEmpty {
                Text(suffix)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Stepper("", value: value, in: range)
                .labelsHidden()
        }
    }

    private func openNotificationSettings() {
        // Newer macOS pane id, falls back to the legacy id if the new one isn't found.
        let urls = [
            "x-apple.systempreferences:com.apple.Notifications-Settings.extension",
            "x-apple.systempreferences:com.apple.preference.notifications"
        ]
        for s in urls {
            if let url = URL(string: s), NSWorkspace.shared.open(url) { return }
        }
    }

    /// A binding that clamps writes into `range` so typed values stay valid.
    private func clamped(_ b: Binding<Int>, in range: ClosedRange<Int>) -> Binding<Int> {
        Binding(
            get: { b.wrappedValue },
            set: { b.wrappedValue = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}
