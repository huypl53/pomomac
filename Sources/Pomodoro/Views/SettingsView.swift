import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: Settings

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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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

    /// A binding that clamps writes into `range` so typed values stay valid.
    private func clamped(_ b: Binding<Int>, in range: ClosedRange<Int>) -> Binding<Int> {
        Binding(
            get: { b.wrappedValue },
            set: { b.wrappedValue = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}
