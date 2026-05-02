import SwiftUI

struct StatsView: View {
    @EnvironmentObject var stats: Stats
    @State private var confirmReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stats")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            row("Today", count: stats.todayCount, minutes: stats.todayMinutes)
            row("This week", count: stats.weekCount, minutes: stats.weekMinutes)
            row("All time", count: stats.allTimeCount, minutes: stats.totalFocusMinutes)

            HStack {
                Spacer()
                Button(role: .destructive) {
                    confirmReset = true
                } label: {
                    Text("Reset stats").font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .confirmationDialog("Reset all stats?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { stats.reset() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func row(_ label: String, count: Int, minutes: Int) -> some View {
        HStack {
            Text(label).font(.system(size: 12))
            Spacer()
            Text("\(count) \(count == 1 ? "pomodoro" : "pomodoros") · \(formatMinutes(minutes))")
                .font(.system(size: 12))
                .monospacedDigit()
                .foregroundColor(.secondary)
        }
    }

    private func formatMinutes(_ m: Int) -> String {
        if m < 60 { return "\(m)m" }
        return "\(m / 60)h \(m % 60)m"
    }
}
