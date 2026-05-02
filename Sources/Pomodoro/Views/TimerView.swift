import SwiftUI

struct TimerView: View {
    @EnvironmentObject var timer: PomodoroTimer
    @EnvironmentObject var settings: Settings

    var body: some View {
        VStack(spacing: 10) {
            Text(phaseLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            Text(timer.formattedRemaining)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 8) {
                Button(action: timer.toggle) {
                    Text(toggleLabel)
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)

                Button(action: timer.skip) {
                    Text("Skip").frame(maxWidth: .infinity)
                }

                Button(action: timer.reset) {
                    Text("Reset").frame(maxWidth: .infinity)
                }
            }
            .controlSize(.regular)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var phaseLabel: String {
        switch timer.phase {
        case .work:
            return "Work · \(timer.completedWorkInCycle + 1) of \(settings.sessionsUntilLongBreak)"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }

    private var toggleLabel: String {
        switch timer.state {
        case .running: return "Pause"
        case .paused: return "Resume"
        case .idle: return "Start"
        }
    }
}
